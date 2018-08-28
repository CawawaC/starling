// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

import AssetFactory from "./AssetFactory";

declare namespace starling.assets
{
	/** This AssetFactory creates texture assets from ATF files. */
	export class AtfTextureFactory extends AssetFactory
	{
		/** Creates a new instance. */
		public constructor();
	}
}

export default starling.assets.AtfTextureFactory;