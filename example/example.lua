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

  example/example.lua
  lua-ddl
  Created by Masatoshi Teruya on 14/10/05.
 
--]]

local inspect = require('util').inspect;
local Sample = require('./sampleDDL').new();

local src = [[
    set1 'val1';
    set2 'val1' 'val2';
    set3 'val1' 'val2' 'val3';
    sets 'val1' 'val2' 'val3' 'val4' 'last_val';
    function get()
    end
]];
local isstr = true;

-- str
print( inspect( assert( Sample:eval( src, isstr ) ) ) );
-- file
print( inspect( assert( Sample:eval( './data.txt' ) ) ) );
