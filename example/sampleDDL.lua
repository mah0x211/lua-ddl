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

  example/sample.lua
  lua-ddl
  Created by Masatoshi Teruya on 14/10/05.
 
--]]

local inspect = require('util').inspect;
local DDL = require('ddl');

local SampleDDL = {};


function SampleDDL:_onStartDDL( merge )
    return {};
end


function SampleDDL:_onCompleteDDL( data )
    return data;
end


local function setdata( data, field, ... )
    local item = data[field];
    
    if item then
        local nitem = #item + 1;
        item[nitem] = ...;
        return nitem;
    end
    
    item = { ... };
    data[field] = item;
    
    return 1;
end


function SampleDDL:set1( data, ... )
    setdata( data, 'set1', ... );
    return false;
end


function SampleDDL:set2( data, ... )
    return setdata( data, 'set2', ... ) < 2;
end


function SampleDDL:set3( data, ... )
    return setdata( data, 'set3', ... ) < 3;
end


function SampleDDL:sets( data, ... )
    setdata( data, 'sets', ... );
    return true;
end


function SampleDDL:get( data, fn )
    if type( fn ) ~= 'function' then
        return false, 'get must be function';
    end
    
    setdata( data, 'get', fn );
end

-- exports
return {
    new = function( sandbox )
        return DDL.new( SampleDDL, sandbox );
    end    
};

