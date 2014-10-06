--[[

  Copyright (C) 2014 Masatoshi Teruya
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  ddl.lua
  lua-ddl
  Created by Masatoshi Teruya on 14/10/05.
 
--]]
local util = require('util');
local eval = util.eval;
local evalfile = util.evalfile;
local toReg = require('path').toReg;
local DDL = require('halo').class.DDL;


local function createMsg( src, isstr, prop )
    local info = debug.getinfo( 3 );
    local pos = 1;
    local code;
    
    if isstr == true then
        for _, line in ipairs( util.string.split( src, '\n' ) ) do
            if pos == info.currentline then
                code = line;
                break;
            end
            pos = pos + 1;
        end
    else
        local file = io.open( info.source:sub( 2 ) );
        
        for line in file:lines() do
            if pos == info.currentline then
                code = line;
                break;
            end
            pos = pos + 1;
        end
        file:close();
    end
    
    return ('attempt to define global variable: %q\ndata source at:\n\t%s:%d: %q'):format(
        prop, info.short_src, info.currentline, code
    );
end


local function reader( self, sandbox, onComplete )
    return function( src, isstr )
        local data = {};
        local fn, err, co;
        -- lock global
        local env = setmetatable( sandbox, {
            __newindex = function( _, prop )
                local msg = createMsg( src, isstr, prop );
                error( msg, 3 );
            end
        });

        if type( src ) ~= 'string' then
            return nil, 'first argument must be string';
        -- eval source
        elseif isstr == true then
            fn, err = eval( src, env );
        else
            -- relative to absolute
            src, err = toReg( src );
            if not err then
                -- eval file
                fn, err = evalfile( src, env, 't' );
            end
        end
        
        -- evaluation error
        if err then
            return nil, err;
        end
    
        -- preprocess
        self.data = data;
        -- run in coroutine
        co = coroutine.create( fn );
        err = select( 2, coroutine.resume( co ) );
        if not err and coroutine.status( co ) == 'suspended' then
            err = 'should not suspend coroutine';
        end
        -- postprocess
        data = not err and onComplete( self ) or nil;
        self.data = nil;
    
        return data, err;
    end
end


local function currying( self, method )
    return function( ... )
        return method( self, ... );
    end;
end


function DDL:init( sandbox )
    local index = getmetatable( self ).__index;
    local onComplete = index.onComplete;
    
    if type( onComplete ) ~= 'function' then
        error( 'delegate method "onComplete" must be function' );
    elseif sandbox and type( sandbox ) ~= 'table' then
        error( '"sandbox" must be returned table' );
    else
        sandbox = {};
    end
    
    -- remove unused methods
    for _, k in ipairs({ 'init', 'constructor', 'onComplete' }) do
        rawset( index, k, nil );
    end
    
    -- append sandbox
    for k, v in pairs( index ) do
        if sandbox[k] then
            error( ('%q already defined at sandbox table'):format( k ) );
        end
        sandbox[k] = currying( self, v );
        index[k] = nil;
    end
    
    return reader( self, sandbox, onComplete );
end


function DDL:onComplete()
    return self.data;
end

return DDL.exports;
