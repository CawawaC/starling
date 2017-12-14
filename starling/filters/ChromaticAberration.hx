package starling.filters;

import flash.errors.ArgumentError;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Program3D;

import openfl.Vector;

import starling.core.Starling;
import starling.textures.Texture;
import starling.utils.Color;


class ChromaticAberration extends FragmentFilter
{
    private var mShaderProgram:Program3D;
  
    private static inline var PROGRAM_NAME:String = "CA";
	
	private var constants:Vector<Float>;
	private var _program:String;
	public var _intensity:Float;
	public var _angle:Float;
	 
    public function new(matrix:Vector<Float>=null)
    {
        super();
		
		this.constants = new Vector<Float>(4);
	    _intensity = 10;
		_angle = Math.PI;
		_intensity = _intensity/1000;
		var x:Float = _intensity*Math.cos(_angle);
		var y:Float = -_intensity*Math.sin(_angle);
		this.constants[0] = x;
		this.constants[1] = y;
		this.constants[2] = -x;
		this.constants[3] = -y;  
    }
    
    /** @private */
    private override function createPrograms():Void
    {
        var target:Starling = Starling.current;
        
        if (target.hasProgram(PROGRAM_NAME))
        {
            mShaderProgram = target.getProgram(PROGRAM_NAME);
        }
        else
        {      
			
			
			 // fc0-3: matrix
            // fc4:   offset
            // fc5:   minimal allowed color value
            var fragmentShader:String =
			
			"tex ft0, v0, fs0 <2d, clamp, linear, mipnone> \n"
	        + "add ft3.xyzw, fc0.xyzw, v0.xyxy \n" // ft3 = fc0 (parametre de me filtre) + v0(coordonnees de la texture)
	         + "tex ft1, ft3.xy, fs0 <2d, clamp, linear, mipnone> \n"
	         + "tex ft2, ft3.zw, fs0 <2d, clamp, linear, mipnone> \n"
	         + "mov ft0.x, ft1.x \n"
	         + "mov ft0.z, ft2.z \n"
	         + "mov oc, ft0 \n";
               /* "tex ft0, v0,  fs0 <2d, clamp, linear, mipnone>  \n" + // read texture color
                "max ft0, ft0, fc5              \n" + // avoid division through zero in next step
                "div ft0.xyz, ft0.xyz, ft0.www  \n" + // restore original (non-PMA) RGB values
                "m44 ft0, ft0, fc0              \n" + // multiply color with 4x4 matrix
                "add ft0, ft0, fc4              \n" + // add offset
                "mul ft0.xyz, ft0.xyz, ft0.www  \n" + // multiply with alpha again (PMA)
                "mov oc, ft0                    \n";  // copy to output*/
            
            mShaderProgram = target.registerProgramFromSource(PROGRAM_NAME,
                FragmentFilter.STD_VERTEX_SHADER, fragmentShader);
        }
    }
    
    /** @private */
    private override function activate(pass:Int, context:Context3D, texture:Texture):Void
    {
	  _intensity = _intensity/1000;
		var x:Float = _intensity*Math.cos(_angle);
		var y:Float = -_intensity*Math.sin(_angle);
		this.constants[0] = x;
		this.constants[1] = y;
		this.constants[2] = -x;
		this.constants[3] = -y;
		
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, this.constants, Std.int(this.constants.length/4));
       // context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, MIN_COLOR);
        context.setProgram(mShaderProgram);
		
		/*context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, this.constants, int(this.constants.length/4));
context.setProgram(mShaderProgram);	*/
    }   
}