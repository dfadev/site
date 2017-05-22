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

import Array;
import haxe.ds.ObjectMap;
import Type.ValueType;
import haxe.ds.IntMap;
import haxe.ds.StringMap;

class Cloner {

    var cache:ObjectMap<Dynamic,Dynamic>;
    var classHandles:Map<String,Dynamic->Dynamic>;
    var stringMapCloner:MapCloner<String>;
    var intMapCloner:MapCloner<Int>;

    public function new():Void {
        stringMapCloner = new MapCloner(this,StringMap);
        intMapCloner = new MapCloner(this,IntMap);
        classHandles = new Map<String,Dynamic->Dynamic>();
        classHandles.set('String',returnString);
        classHandles.set('Array',cloneArray);
        classHandles.set('haxe.ds.StringMap',stringMapCloner.clone);
        classHandles.set('haxe.ds.IntMap',intMapCloner.clone);
    }

    function returnString(v:String):String {
        return v;
    }

    public function clone <T> (v:T):T {
        cache = new ObjectMap<Dynamic,Dynamic>();
        var outcome:T = _clone(v);
        cache = null;
        return outcome;
    }

    public function _clone <T> (v:T):T {
        #if js
        if(Std.is(v, String))
            return v;
        #end
        if(Type.getClassName(cast v) != null)
            return v;
        switch(Type.typeof(v)){
            case TNull:
                return null;
            case TInt:
                return v;
            case TFloat:
                return v;
            case TBool:
                return v;
            case TObject:
                return handleAnonymous(v);
            case TFunction:
                return null;
            case TClass(c):
                if(!cache.exists(v))
                    cache.set(v,handleClass(c, v));
                return cache.get(v);
            case TEnum(e):
                return v;
            case TUnknown:
                return null;
        }
    }

    function handleAnonymous (v:Dynamic):Dynamic {
        var properties:Array<String> = Reflect.fields(v);
        var anonymous:Dynamic = {};
        for (i in 0...properties.length) {
            var property:String = properties[i];
            Reflect.setField(anonymous, property, _clone(Reflect.getProperty(v, property)));
        }
        return anonymous;
    }

    function handleClass <T> (c:Class<T>,inValue:T):T {
        var handle:T->T = classHandles.get(Type.getClassName(c));
        if(handle == null)
            handle = cloneClass;
        return handle(inValue);
    }

    function cloneArray <T> (inValue:Array<T>):Array<T> {
        var array:Array<T> = inValue.copy();
        for (i in 0...array.length)
            array[i] = _clone(array[i]);
        return array;
    }

    function cloneClass <T> (inValue:T):T {
        var outValue:T = Type.createEmptyInstance(Type.getClass(inValue));
        var fields:Array<String> = Reflect.fields(inValue);
        for (i in 0...fields.length) {
            var field = fields[i];
            var property = Reflect.getProperty(inValue, field);
            Reflect.setField(outValue, field, _clone(property));
        }
        return outValue;
    }

    public function merge (v1:Dynamic, v2:Dynamic):Dynamic {
		if (v2 == null) return v1;
        var properties:Array<String> = Reflect.fields(v1);
        for (i in 0...properties.length) {
            var property:String = properties[i];
            Reflect.setField(v2, property, _merge(Reflect.getProperty(v1, property), Reflect.getProperty(v2, property)));
        }
        return v2;
    }

    public function _merge(v1:Dynamic, v2:Dynamic):Dynamic {
        #if js
        if(Std.is(v1, String))
            return v1;
        #end
        if(Type.getClassName(cast v1) != null)
            return v1;
        switch(Type.typeof(v1)){
            case TNull:
                return null;
            case TInt:
                return v1;
            case TFloat:
                return v1;
            case TBool:
                return v1;
            case TObject:
                return merge(v1, v2);
            case TFunction:
                return v1;
            case TClass(c):
				return v1;
                //if(!cache.exists(v))
                    //cache.set(v,handleClass(c, v));
                //return cache.get(v);
            case TEnum(e):
                return v1;
            case TUnknown:
                return null;
        }
    }
}
