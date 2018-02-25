import Vector from "openfl/Vector";

import Starling from "starling/core/Starling";
import Button from "starling/display/Button";
import DisplayObject from "starling/display/DisplayObject";
import Image from "starling/display/Image";
import Sprite from "starling/display/Sprite";
import EnterFrameEvent from "starling/events/EnterFrameEvent";
import Event from "starling/events/Event";
import BitmapFont from "starling/text/BitmapFont";
import TextField from "starling/text/TextField";
import TextFormat from "starling/text/TextFormat";
import Texture from "starling/textures/Texture";
import StringUtil from "starling/utils/StringUtil";

import MenuButton from "./../utils/menuButton";
import Constants from "./../constants";
import Game from "./../game";
import Scene from "./scene";

class BenchmarkScene extends Scene
{
    static FRAME_TIME_WINDOW_SIZE = 10;
    static MAX_FAIL_COUNT = 100;

    constructor()
    {
        super();

        // the container will hold all test objects
        this._container = new Sprite();
        this._container.x = Constants.CenterX;
        this._container.y = Constants.CenterY;
        this._container.touchable = false; // we do not need touch events on the test objects --
                                      // thus, it is more efficient to disable them.
        this.addChildAt(this._container, 0);

        this._statusText = new TextField(Constants.GameWidth - 40, 30);
        this._statusText.format = new TextFormat(BitmapFont.MINI, BitmapFont.NATIVE_SIZE * 2);
        this._statusText.x = 20;
        this._statusText.y = 10;
        this.addChild(this._statusText);

        this._startButton = new MenuButton("Start benchmark");
        this._startButton.addEventListener(Event.TRIGGERED, this.onStartButtonTriggered);
        this._startButton.x = Constants.CenterX - (this._startButton.width / 2);
        this._startButton.y = 20;
        this.addChild(this._startButton);
        
        this._started = false;
        this._frameTimes = new Vector();
        this._objectPool = new Vector();
        this._objectTexture = Game.assets.getTexture("benchmark_object");

        this.addEventListener(Event.ENTER_FRAME, this.onEnterFrame);
    }
    
    dispose()
    {
        this.removeEventListener(Event.ENTER_FRAME, this.onEnterFrame);
        this._startButton.removeEventListener(Event.TRIGGERED, this.onStartButtonTriggered);

        for (var i = 0; i < this._objectPool.length; i++)
        {
            var object = this._objectPool[i];
            object.dispose();
        }
        super.dispose();
    }

    onStartButtonTriggered = () =>
    {
        console.log("Starting benchmark");

        this._startButton.visible = false;
        this._started = true;
        this._targetFps = Starling.current.nativeStage.frameRate;
        this._frameCount = 0;
        this._failCount = 0;
        this._phase = 0;
        
        if (this._targetFps <= 0) this._targetFps = 60;

        for (var i = 0; i < BenchmarkScene.FRAME_TIME_WINDOW_SIZE; i++)
            this._frameTimes[i] = 1.0 / this._targetFps;

        if (this._resultText != null)
        {
            this._resultText.removeFromParent(true);
            this._resultText = null;
        }
    }

    onEnterFrame = (event, passedTime) =>
    {
        if (!this._started) return;

        this._frameCount++;
        this._container.rotation += event.passedTime * 0.5;
        this._frameTimes[BenchmarkScene.FRAME_TIME_WINDOW_SIZE] = 0.0;

        for (var i = 0; i < BenchmarkScene.FRAME_TIME_WINDOW_SIZE; i++)
            this._frameTimes[i] += passedTime;

        var measuredFps = BenchmarkScene.FRAME_TIME_WINDOW_SIZE / this._frameTimes.shift();

        if (this._phase == 0)
        {
            if (measuredFps < 0.985 * this._targetFps)
            {
                this._failCount++;

                if (this._failCount == BenchmarkScene.MAX_FAIL_COUNT)
                    this._phase = 1;
            }
            else
            {
                this.addTestObjects(16);
                this._container.scale *= 0.99;
                this._failCount = 0;
            }
        }
        if (this._phase == 1)
        {
            if (measuredFps > 0.99 * this._targetFps)
            {
                this._failCount--;

                if (this._failCount == 0)
                this.benchmarkComplete();
            }
            else
            {
                this.removeTestObjects(1);
                this.    _container.scale /= 0.9993720513; // 0.99 ^ (1/16)
            }
        }

        if (this._frameCount % Math.round(this._targetFps / 4) == 0)
        this._statusText.text = this._container.numChildren + " objects";
    }

    addTestObjects = (count) =>
    {
        var scale = 1.0 / this._container.scale;

        for (var i = 0; i < count; i++)
        {
            var egg = this.getObjectFromPool();
            var distance = (100 + Math.random() * 100) * scale;
            var angle = Math.random() * Math.PI * 2.0;

            egg.x = Math.cos(angle) * distance;
            egg.y = Math.sin(angle) * distance;
            egg.rotation = angle + Math.PI / 2.0;
            egg.scale = scale;

            this._container.addChild(egg);
        }
    }

    removeTestObjects(count)
    {
        var numChildren = this._container.numChildren;

        if (count >= numChildren)
            count  = numChildren;

        for (var i = 0; i < count; i++)
            this.putObjectToPool(this._container.removeChildAt(this._container.numChildren-1));
    }

    getObjectFromPool()
    {
        // we pool mainly to avoid any garbage collection while the benchmark is running

        if (this._objectPool.length == 0)
        {
            var image = new Image(this._objectTexture);
            image.alignPivot();
            image.pixelSnapping = false; // slightly faster (and doesn't work here, anyway)
            return image;
        }
        else
            return this._objectPool.pop();
    }

    putObjectToPool(object)
    {
        this._objectPool[this._objectPool.length] = object;
    }

    benchmarkComplete()
    {
        this._started = false;
        this._startButton.visible = true;
        
        var fps = Starling.current.nativeStage.frameRate;
        var numChildren = this._container.numChildren;
        var resultString = StringUtil.format("Result:\n{0} objects\nwith {1} fps",
                                               [numChildren, fps]);
        console.log(resultString.replace("\n", " "));

        this._resultText = new TextField(240, 200, resultString);
        this._resultText.format.font = "DejaVu Sans";
        this._resultText.format.size = 30;
        this._resultText.x = Constants.CenterX - this._resultText.width / 2;
        this._resultText.y = Constants.CenterY - this._resultText.height / 2;
        
        this.addChild(this._resultText);

        this._container.scale = 1.0;
        this._frameTimes.length = 0;
        this._statusText.text = "";

        for (var i = numChildren - 1; i >= 0; --i)
        {
            this.putObjectToPool(this._container.removeChildAt(i));
        }
    }
}

export default BenchmarkScene;