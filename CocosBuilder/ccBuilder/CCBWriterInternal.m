//
//  Copyright 2011 Viktor Lidholt. All rights reserved.
//

#import "CCBWriterInternal.h"
#import "CCBReaderInternalV1.h"
#import "CCNineSlice.h"
#import "CCButton.h"
#import "CCThreeSlice.h"

#import "NodeInfo.h"
#import "PlugInNode.h"
#import "TexturePropertySetter.h"

@implementation CCBWriterInternal

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark Shortcuts for serializing properties

+ (id) serializePoint:(CGPoint)pt
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:pt.x],
            [NSNumber numberWithFloat:pt.y],
            nil];
}

+ (id) serializeSize:(CGSize)size
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:size.width],
            [NSNumber numberWithFloat:size.height],
            nil];
}

+ (id) serializeBoolPairX:(BOOL)x Y:(BOOL)y
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithBool:x],
            [NSNumber numberWithBool:y],
            nil];
}

+ (id) serializeFloat:(float)f
{
    return [NSNumber numberWithFloat:f];
}

+ (id) serializeInt:(float)d
{
    return [NSNumber numberWithInt:d];
}

+ (id) serializeBool:(float)b
{
    return [NSNumber numberWithBool:b];
}

+ (id) serializeSpriteFrame:(NSString*)spriteFile sheet:(NSString*)spriteSheetFile
{
    if (!spriteFile)
    {
        spriteFile = @"";
    }
    if (!spriteSheetFile || [spriteSheetFile isEqualToString:kCCBUseRegularFile])
    {
        spriteSheetFile = @"";
    }
    return [NSArray arrayWithObjects:spriteSheetFile, spriteFile, nil];
}

+ (id) serializeColor3:(ccColor3B)c
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:c.r],
            [NSNumber numberWithInt:c.g],
            [NSNumber numberWithInt:c.b],
            nil];
}

+ (id) serializeBlendFunc:(ccBlendFunc)bf
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithInt:bf.src],
            [NSNumber numberWithInt:bf.dst],
            nil];
}

#pragma mark Writer

+ (NSMutableDictionary*) dictionaryFromCCObject:(CCNode *)node
{
    NodeInfo* info = node.userData;
    PlugInNode* plugIn = info.plugIn;
    NSMutableDictionary* extraProps = info.extraProps;
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    NSMutableArray* props = [NSMutableArray array];
    
    NSMutableArray* plugInProps = plugIn.nodeProperties;
    int plugInPropsCount = [plugInProps count];
    for (int i = 0; i < plugInPropsCount; i++)
    {
        NSMutableDictionary* propInfo = [plugInProps objectAtIndex:i];
        NSString* type = [propInfo objectForKey:@"type"];
        NSString* name = [propInfo objectForKey:@"name"];
        id serializedValue; 
        
        // Ignore separators and graphical stuff
        if ([type isEqualToString:@"Separator"]) continue;
        
        // Handle different type of properties
        if ([plugIn dontSetInEditorProperty:name])
        {
            // Get the serialized value from the extra props
            serializedValue = [extraProps objectForKey:name];
        }
        else if ([type isEqualToString:@"Position"]
            || [type isEqualToString:@"Point"]
            || [type isEqualToString:@"PointLock"])
        {
            CGPoint pt = [[node valueForKey:name] pointValue];
            serializedValue = [CCBWriterInternal serializePoint:pt];
        }
        else if ([type isEqualToString:@"Size"])
        {
            CGSize size = [[node valueForKey:name] sizeValue];
            serializedValue = [CCBWriterInternal serializeSize:size];
        }
        else if ([type isEqualToString:@"Scale"]
                 || [type isEqualToString:@"ScaleLock"])
        {
            float x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] floatValue];
            float y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] floatValue];
            serializedValue = [CCBWriterInternal serializePoint:ccp(x,y)];
        }
        else if ([type isEqualToString:@"Float"]
                 || [type isEqualToString:@"Degrees"])
        {
            float f = [[node valueForKey:name] floatValue];
            serializedValue = [CCBWriterInternal serializeFloat:f];
        }
        else if ([type isEqualToString:@"Integer"]
                 || [type isEqualToString:@"Byte"])
        {
            int d = [[node valueForKey:name] intValue];
            serializedValue = [CCBWriterInternal serializeInt:d];
        }
        else if ([type isEqualToString:@"Check"])
        {
            BOOL check = [[node valueForKey:name] boolValue];
            serializedValue = [CCBWriterInternal serializeBool:check];
        }
        else if ([type isEqualToString:@"Flip"])
        {
            BOOL x = [[node valueForKey:[NSString stringWithFormat:@"%@X",name]] boolValue];
            BOOL y = [[node valueForKey:[NSString stringWithFormat:@"%@Y",name]] boolValue];
            serializedValue = [CCBWriterInternal serializeBoolPairX:x Y:y];
        }
        else if ([type isEqualToString:@"SpriteFrame"])
        {
            NSString* spriteFile = [extraProps objectForKey:name];
            NSString* spriteSheetFile = [extraProps objectForKey:[NSString stringWithFormat:@"%@Sheet",name]];
            serializedValue = [CCBWriterInternal serializeSpriteFrame:spriteFile sheet:spriteSheetFile];
        }
        else if ([type isEqualToString:@"Color3"])
        {
            NSValue* colorValue = [node valueForKey:name];
            ccColor3B c;
            [colorValue getValue:&c];
            serializedValue = [CCBWriterInternal serializeColor3:c];
        }
        else if ([type isEqualToString:@"Blendmode"])
        {
            NSValue* blendValue = [node valueForKey:name];
            ccBlendFunc bf;
            [blendValue getValue:&bf];
            serializedValue = [CCBWriterInternal serializeBlendFunc:bf];
        }
        else if ([type isEqualToString:@"FntFile"])
        {
            NSString* str = [TexturePropertySetter fontForNode:node andProperty:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else if ([type isEqualToString:@"Text"])
        {
            NSString* str = [node valueForKey:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else if ([type isEqualToString:@"FontTTF"])
        {
            NSString* str = [node valueForKey:name];
            if (!str) str = @"";
            serializedValue = str;
        }
        else
        {
            NSLog(@"WARNING Unrecognized property type: %@", type);
        }
        
        NSMutableDictionary* prop = [NSMutableDictionary dictionary];
        [prop setValue:type forKey:@"type"];
        [prop setValue:name forKey:@"name"];
        [prop setValue:serializedValue forKey:@"value"];
        
        [props addObject:prop];
    }
    
    NSString* baseClass = plugIn.nodeClassName;
    
    // Children
    NSMutableArray* children = [NSMutableArray array];
    
    // Visit all children of this node
    if (plugIn.canHaveChildren)
    {
        for (int i = 0; i < [[node children] count]; i++)
        {
            [children addObject:[CCBWriterInternal dictionaryFromCCObject:[[node children] objectAtIndex:i]]];
        }
    }
    
    if (!baseClass) NSLog(@"baseClass: %@ plugIn: %@ nodeInfo: %@ node: %@", baseClass, plugIn, info, node);
    
    // Create node
    [dict setObject:props forKey:@"properties"];
    [dict setObject:baseClass forKey:@"baseClass"];
    [dict setObject:children forKey:@"children"];
    
    // Add code connection props
    NSString* customClass = [extraProps objectForKey:@"customClass"];
    if (!customClass) customClass = @"";
    NSString* memberVarName = [extraProps objectForKey:@"memberVarAssignmentName"];
    if (!memberVarName) memberVarName = @"";
    int memberVarType = [[extraProps objectForKey:@"memberVarAssignmentType"] intValue];
    
    [dict setObject:customClass forKey:@"customClass"];
    [dict setObject:memberVarName forKey:@"memberVarAssignmentName"];
    [dict setObject:[NSNumber numberWithInt:memberVarType] forKey:@"memberVarAssignmentType"];
    
    return dict;
}

@end