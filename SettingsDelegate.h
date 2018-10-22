/*
 *  SettingsDelegate.h
 *  LEDsFlash
 *
 *  Created by Kees van der Bent on 17/07/10.
 *  Copyright 2010 Software Natural. All rights reserved.
 *
 */

@protocol SettingsDelegate

- (void)setBeatIt:(bool)value;
- (void)setBeatLevel:(float)level;

@end

typedef enum
{    
    INPUT_SOURCE_BEAT  = 1,
    INPUT_SOURCE_SHAKE = 2,
    INPUT_SOURCE_TAP   = 4,
    INPUT_SOURCE_MOVE  = 8
} InputSource;