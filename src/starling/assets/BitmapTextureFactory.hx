// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================


package starling.assets;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.system.LoaderContext;
import openfl.utils.ByteArray;

import starling.textures.Texture;
import starling.utils.Execute;

/** This AssetFactory creates texture assets from bitmaps and image files. */
class BitmapTextureFactory extends AssetFactory
{
    /** Creates a new instance. */
    public function new()
    {
        super();
        addMimeTypes(["image/png", "image/jpg", "image/jpeg", "image/gif"]);
        addExtensions(["png", "jpg", "jpeg", "gif"]);
    }

    /** @inheritDoc */
    override public function canHandle(reference:AssetReference):Bool
    {
        return Std.is(reference.data, Bitmap) || Std.is(reference.data, BitmapData) ||
            super.canHandle(reference);
    }

    /** @inheritDoc */
    override public function create(reference:AssetReference, helper:AssetFactoryHelper,
                                    onComplete:String->Dynamic->Void, onError:String->Void):Void
    {
        var texture:Texture;
        var url:String = reference.url;
        var data:Dynamic = reference.data;
        
        var onReloadError:String->Void = null;
        var reload:String->(BitmapData->Void)->Void = null;
        var onBitmapDataCreated:BitmapData->Void = null;
        var createFromBitmapData:BitmapData->Void = null;
        var onLoadComplete:Bitmap->Void = null;
        
        onReloadError = function (error:String):Void
        {
            helper.log("Texture restoration failed for " + url + ". " + error);
            helper.onEndRestore();
        }
        
        reload = function (url:String, onComplete:BitmapData->Void):Void
        {
            helper.loadDataFromUrl(url, function(?data:ByteArray, ?mimeType:String, ?name:String, ?extension:String):Void
            {
               createBitmapDataFromByteArray(data, onComplete, onReloadError);
            }, onReloadError);
        }
        
        onBitmapDataCreated = function (bitmapData:BitmapData):Void
        {
            helper.executeWhenContextReady(createFromBitmapData, [bitmapData]);
        }

        createFromBitmapData = function (bitmapData:BitmapData):Void
        {
            reference.textureOptions.onReady = function(_):Void
            {
                onComplete(reference.name, texture);
            };

            texture = Texture.fromData(bitmapData, reference.textureOptions);

            if (url != null)
            {
                texture.root.onRestore = function(_):Void
                {
                    helper.onBeginRestore();

                    reload(url, function(bitmapData:BitmapData):Void
                    {
                        helper.executeWhenContextReady(function():Void
                        {
                            texture.root.uploadBitmapData(bitmapData);
                            helper.onEndRestore();
                        });
                    });
                };
            }
        }
        
        if (Std.is(data, Bitmap))
        {
            onBitmapDataCreated(cast(data, Bitmap).bitmapData);
        }
        else if (Std.is(data, BitmapData))
        {
            onBitmapDataCreated(cast data);
        }
        else if (Std.is(data, #if commonjs ByteArray #else ByteArrayData #end))
        {
            createBitmapDataFromByteArray(cast data, onBitmapDataCreated, onError);
        }
    }

    /** Called by 'create' to convert a ByteArray to a BitmapData.
     *
     *  @param data        A ByteArray that contains image data
     *                     (like the contents of a PNG or JPG file).
     *  @param onComplete  Called with the BitmapData when successful.
     *                     <pre>function(bitmapData:BitmapData):void;</pre>
     *  @param onError     To be called when creation fails for some reason.
     *                     <pre>function(error:String):void</pre>
     */
    private function createBitmapDataFromByteArray(data:ByteArray,
                                                   onComplete:BitmapData->Void, onError:String->Void):Void
    {
        var loader:Loader;
        var loaderInfo:LoaderInfo;
        
        var onIoError:IOErrorEvent->Void = null;
        var onLoaderComplete:Dynamic->Void = null;
        var complete:Dynamic->Void = null;
        var cleanup:Void->Void = null;
        
        onIoError = function (event:IOErrorEvent):Void
        {
            cleanup();
            Execute.execute(onError, [event.text]);
        }

        onLoaderComplete = function (event:Dynamic):Void
        {
            complete(cast (event.target.content, Bitmap).bitmapData);
        }

        complete = function (bitmapData:BitmapData):Void
        {
            cleanup();
            Execute.execute(onComplete, [bitmapData]);
        }

        cleanup = function ():Void
        {
            loaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIoError);
            loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
        }
        
        loader = new Loader();
        loaderInfo = loader.contentLoaderInfo;
        loaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
        loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
        var loaderContext:LoaderContext = new LoaderContext();
        #if flash
        @:require(flash11) loaderContext.imageDecodingPolicy = flash.system.ImageDecodingPolicy.ON_LOAD;
        #end
        loader.loadBytes(data, loaderContext);
    }
}