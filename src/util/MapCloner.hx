/*
License
=======

The MIT License (MIT)

Copyright (c) 2015 Thomas Uster

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
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package util;

import util.Cloner;
import Type.ValueType;
import Map.IMap;

class MapCloner<K>{

    var cloner:Cloner;
    var type:Class<IMap<K,Dynamic>>;
    var noArgs:Array<Dynamic>;

    public function new(cloner:Cloner, type:Class<IMap<K,Dynamic>>):Void {
        this.cloner = cloner;
        this.type = type;
        noArgs = [];
    }

    public function clone <K,Dynamic> (inValue:IMap<K,Dynamic>):IMap<K,Dynamic> {
        var inMap:IMap<K,Dynamic> = inValue;
        var map:IMap<K,Dynamic> = cast Type.createInstance(type, noArgs);
        for (key in inMap.keys()) {
            map.set(key, cloner._clone(inMap.get(key)));
        }
        return map;
    }
}
