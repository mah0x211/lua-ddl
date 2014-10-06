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
local Sample = require('halo').class.Sample;

Sample.inherits {
    'ddl.DDL'
};

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


function Sample:set1( ... )
    setdata( self.data, 'set1', ... );
end


function Sample:set2( ... )
    local this = self;
    
    setdata( self.data, 'set2', ... );
    
    return function( ... )
        setdata( this.data, 'set2', ... );
    end
end


function Sample:set3( ... )
    local this = self;
    local narg = setdata( self.data, 'set3', ... );
    local nextArg;
    
    nextArg = function( ... )
        narg = setdata( this.data, 'set3', ... );
        return narg < 4 and nextArg or nil;
    end
    
    return nextArg;
end


function Sample:sets( ... )
    local this = self;
    local nextArg;
    
    setdata( self.data, 'sets', ... );
    
    nextArg = function( ... )
        setdata( this.data, 'sets', ... );
        return nextArg;
    end
    
    return nextArg;
end


function Sample:onComplete()
    print( 'complete' );
    return self.data;
end


return Sample.exports;

