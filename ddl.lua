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
-- modules
local strsplit = require('util.string').split;
local eval = require('util').eval;
local evalfile = require('util').evalfile;
local toReg = require('path').toReg;
local getinfo = debug.getinfo;

-- private functions
local function evalSrc( src, isstr, sandbox )
    local err;
    
    -- eval source string
    if isstr == true then
        return eval( src, sandbox );
    end
    
    -- eval file
    -- relative to absolute
    src, err = toReg( src );
    if not err then
        return evalfile( src, sandbox, 't' );
    end
    
    return nil, err;
end


local function getSrcInfo( src, isstr )
    local lv = 4;
    local info = getinfo( lv );
    
    while info do
        if isstr == true then
            if info.source == src then
                break;
            end
        elseif info.source:sub(2) == src then
            break;
        end
        
        lv = lv + 1;
        info = getinfo( lv );
    end
    
    return info;
end


local function abortMsg( src, isstr, fmt, ... )
    local info = getSrcInfo( src, isstr );
    local pos = 1;
    local code = '';
    
    if isstr == true then
        for _, line in ipairs( strsplit( src, '\n' ) ) do
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


-- class
local DDL = require('halo').class.DDL;

function DDL:init( delegate, sandbox )
    local own = protected( self );
    
    -- check delegator
    if type( delegate._onStartDDL ) ~= 'function' then
        error( 'delegate._onStartDDL must be function' );
    elseif type( delegate._onCompleteDDL ) ~= 'function' then
        error( 'delegate._onCompleteDDL must be function' );
    -- sandbox
    elseif sandbox == nil then
        sandbox = {};
    elseif type( sandbox ) ~= 'table' then
        error( '"sandbox" must be table' );
    end
    
    -- save to protected
    own.delegate = delegate;
    own.env = {};
    
    -- create environment
    for k, v in pairs( sandbox ) do
        -- check the duplication
        if delegate[k] then
            error( ('%q already defined at DDL field'):format( k ) );
        end
        -- append sandbox values into env
        own.env[k] = v;
    end
    
    return self;
end


-- source reader
function DDL:eval( src, isstr, merge )
    local own = protected( self );
    local delegate = own.delegate;
    local abort = function( _, msg )
        error( abortMsg( src, isstr, msg ), -1 );
    end
    local data = {};
    local sandbox = {};
    local fn, err, ok, method;
    
    -- check merge data
    if merge and type( merge ) ~= 'table' then
        return nil, 'data must be table';
    elseif type( src ) ~= 'string' then
        return nil, 'src must be string';
    end
    
    -- create sandbox
    for k, v in pairs( own.env ) do
        sandbox[k] = v;
    end
    setmetatable( sandbox, {
        -- protection
        __metatable = true,
        -- global assignments
        __newindex = function( _, field, v )
            method = delegate[field];
            -- call delegate method
            if type( method ) == 'function' then
                ok, err = method( delegate, data, v );
                if err then
                    error( abortMsg( src, isstr, err ), -1 );
                end
            else
                error( abortMsg( src, isstr, 'attempt to define global variable: %q', field ), -1 );
            end
        end,
        
        -- lookup field
        __index = function( _, field )
            method = delegate[field];
            -- create proxy
            if type( method ) == 'function' then
                return setmetatable({},{
                    -- protection
                    __metatable = true,
                    __newindex = function( _, k )
                        error( abortMsg( src, isstr, 'attempt to define property: %q', k ), -1 );
                    end,
                    __index = function( _, k )
                        error( abortMsg( src, isstr, 'attempt to undefined property: %q', k ), -1 );
                    end,
                    -- call delegate method
                    __call = function( proxy, val )
                        ok, err = method( delegate, data, val );
                        if err then
                            error( abortMsg( src, isstr, err ), -1 );
                        -- can receive next value
                        elseif ok then
                            return proxy;
                        end
                    end
                });
            end
        end
    });

    -- eval source
    fn, err = evalSrc( src, isstr, sandbox );
    if err then
        return nil, err;
    end
    
    -- preprocess
    data = delegate:_onStartDDL( merge );
    -- run compiled source in protected mode
    err = select( 2, pcall( fn ) );
    -- postprocess
    data = not err and delegate:_onCompleteDDL( data ) or nil;
    
    return data, err;
end

return DDL.exports;
