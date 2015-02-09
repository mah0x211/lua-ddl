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

local function getSrcInfo( src, isstr )
    local lv = 4;
    local info = debug.getinfo( lv );
    
    while info do
        if isstr == true then
            if info.source == src then
                break;
            end
        elseif info.source:sub(2) == src then
            break;
        end
        
        lv = lv + 1;
        info = debug.getinfo( lv );
    end
    
    return info;
end


local function createMsg( src, isstr, fmt, ... )
    local info = getSrcInfo( src, isstr );
    local pos = 1;
    local code = '';
    
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
        
        if file then
            for line in file:lines() do
                if pos == info.currentline then
                    code = line;
                    break;
                end
                pos = pos + 1;
            end
            file:close();
        end
    end
    
    if #{...} > 0 then
        fmt = fmt:format( ... );
    end
    
    return ('%s at %s:%d: %q'):format(
        fmt, info.short_src, info.currentline, code
    );
end


local function reader( self, env, onStart, onComplete )
    return function( src, isstr, merge )
        local data = {};
        local index = getmetatable( self ).__index;
        local abort = function( _, msg )
            error( createMsg( src, isstr, msg ), -1 );
        end
        local sandbox, fn, err;
        
        -- check merge data
        if merge and type( merge ) ~= 'table' then
            return nil, 'data must be table';
        elseif type( src ) ~= 'string' then
            return nil, 'src must be string';
        end
        
        -- copy env values into sandbox
        sandbox = {};
        for k, v in pairs( env ) do
            sandbox[k] = v;
        end
        -- lock sandbox
        setmetatable( sandbox, {
            __metatable = true,
            __newindex = function( _, prop )
                error( createMsg( src, isstr, 
                    'attempt to define global variable: %q', prop
                ), -1 );
            end
        });
        
        -- eval source
        if isstr == true then
            fn, err = eval( src, sandbox );
        else
            -- relative to absolute
            src, err = toReg( src );
            if not err then
                -- eval file
                fn, err = evalfile( src, sandbox, 't' );
            end
        end
        
        -- evaluation error
        if err then
            return nil, err;
        end
        
        -- preprocess
        self.data = data;
        onStart( self, merge );
        index['abort'] = abort;
        
        err = select( 2, pcall( fn ) );
        
        -- postprocess
        index['abort'] = nil;
        data = not err and onComplete( self ) or nil;
        self.data = nil;
        
        return data, err;
    end
end


local function currying( self, method )
    return setmetatable({},{
        __call = function( _, ... )
            return method( self, true, ... );
        end,
        __newindex = function( _, ... )
            return method( self, false, ... );
        end
    });
end


local DDL = require('halo').class.DDL;

function DDL:init( sandbox )
    local index = getmetatable( self ).__index;
    local onStart = index.onStart;
    local onComplete = index.onComplete;
    local env = {};
    
    if type( onStart ) ~= 'function' then
        error( 'delegate method "onStart" must be function' );
    elseif type( onComplete ) ~= 'function' then
        error( 'delegate method "onComplete" must be function' );
    elseif sandbox == nil then
        sandbox = {};
    elseif type( sandbox ) ~= 'table' then
        error( '"sandbox" must be table' );
    end
    
    -- remove unused methods
    for _, k in ipairs({ 'init', 'constructor', 'onStart', 'onComplete' }) do
        rawset( index, k, nil );
    end
    
    -- append carried index values into env
    for k, v in pairs( index ) do
        if sandbox[k] then
            error( ('%q already defined at sandbox table'):format( k ) );
        end
        env[k] = currying( self, v );
        index[k] = nil;
    end
    -- append sandbox values into env
    for k, v in pairs( sandbox ) do
        env[k] = v;
    end

    return reader( self, env, onStart, onComplete );
end


function DDL:onStart()
    -- default: do nothing
end


function DDL:onComplete()
    return self.data;
end


return DDL.exports;
