@ECHO off

ECHO Generate transparent TGA frames, MKS and VTEX files

SET folder=%~fs1
SET output=%2
SET color=%3

convert.exe -fill "#010101" -opaque %color% -transparent "#010101" "%folder%\%output% *.tga" "%folder%\\%output%.tga"

ECHO sequence 0 > %folder%\\%output%.mks
setlocal enableextensions enabledelayedexpansion
SET /A COUNT=0
FOR %%f IN ("%folder%\%output% *.tga") DO (
    ECHO frame %output%-!COUNT!.tga 1 >> %folder%\\%output%.mks
	SET /A COUNT+=1
)


(
	ECHO ^<^^!-- dmx encoding keyvalues2_noids 1 format vtex 1 --^>
	ECHO "CDmeVtex"
	ECHO {
	ECHO 	"m_inputTextureArray" "element_array" 
	ECHO 	[
	ECHO 		"CDmeInputTexture"
	ECHO 		{
	ECHO 			"m_name" "string" "0"
	ECHO 			"m_fileName" "string" "materials/particle/%output%/%output%.mks"
	ECHO 			"m_colorSpace" "string" "srgb"
	ECHO 			"m_typeString" "string" "2D"
	ECHO 		}
	ECHO 	]
	ECHO 	"m_outputTypeString" "string" "2D"
	ECHO 	"m_outputFormat" "string" "DXT5"
	ECHO 	"m_textureOutputChannelArray" "element_array"
	ECHO 	[
	ECHO 		"CDmeTextureOutputChannel"
	ECHO 		{
	ECHO 			"m_inputTextureArray" "string_array"
	ECHO 				[
	ECHO 					"0"
	ECHO 				]
	ECHO 			"m_srcChannels" "string" "rgba"
	ECHO 			"m_dstChannels" "string" "rgba"
	ECHO 			"m_mipAlgorithm" "CDmeImageProcessor"
	ECHO 			{
	ECHO 				"m_algorithm" "string" ""
	ECHO 				"m_stringArg" "string" ""
	ECHO 				"m_vFloat4Arg" "vector4" "0 0 0 0"
	ECHO 			}
	ECHO 			"m_outputColorSpace" "string" "srgb"
	ECHO 		}
	ECHO 	]
	ECHO }
) > %folder%\\%output%.vtex