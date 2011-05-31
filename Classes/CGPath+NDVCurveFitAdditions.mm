/*
 * CGPath+NDVCurveFitAdditions.mm
 *
 * Created by Nathan de Vries on 26/08/10.
 *
 * Copyright (c) 2008-2011, Nathan de Vries.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of any
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */


#import "CGPath+NDVCurveFitAdditions.h"
#import "bezier-utils.h"


CGPathRef CGPathCreateByFittingCurveThroughCGPoints(NSArray* points, CGFloat smoothing) {
    
    Geom::Point* rawPoints;
    CGMutablePathRef resultPath = CGPathCreateMutable();
    
    for (NSUInteger i = 0; i < [points count]; i++) {
        CGPoint point = [(NSValue *)[points objectAtIndex:i] CGPointValue];
        rawPoints[i] = Geom::Point(point.x, point.y);
    }
    
    NSUInteger maxSegments = 256;
    Geom::Point* fittedPointsBuffer;
    fittedPointsBuffer = ((Geom::Point *)malloc(sizeof(Geom::Point) * maxSegments * 4 ));
    
    NSUInteger segments = bezier_fit_cubic_r(fittedPointsBuffer, rawPoints, [points count], smoothing, maxSegments);
    
    if (segments > 0) {
        CGPoint tempPoints[3];
        NSUInteger segmentElement;
        
        tempPoints[0].x = (CGFloat)fittedPointsBuffer[0][Geom::X];
        tempPoints[0].y = (CGFloat)fittedPointsBuffer[0][Geom::Y];
        
        CGPathMoveToPoint(resultPath, NULL, tempPoints[0].x, tempPoints[0].y);
        
        for (NSUInteger i = 0; i < segments; i++) {
            segmentElement = (i * 4) + 1;
            
            tempPoints[0].x = (CGFloat)fittedPointsBuffer[segmentElement][Geom::X];
            tempPoints[0].y = (CGFloat)fittedPointsBuffer[segmentElement++][Geom::Y];
            tempPoints[1].x = (CGFloat)fittedPointsBuffer[segmentElement][Geom::X];
            tempPoints[1].y = (CGFloat)fittedPointsBuffer[segmentElement++][Geom::Y];
            tempPoints[2].x = (CGFloat)fittedPointsBuffer[segmentElement][Geom::X];
            tempPoints[2].y = (CGFloat)fittedPointsBuffer[segmentElement][Geom::Y];
            
            CGPathAddCurveToPoint(resultPath,       // path
                                  NULL,             // transform
                                  tempPoints[0].x,  // cp1x
                                  tempPoints[0].y,  // cp1y
                                  tempPoints[1].x,  // cp2x
                                  tempPoints[1].y,  // cp2y
                                  tempPoints[2].x,  // x
                                  tempPoints[2].y); // y
        }
        
    }
    
    free(rawPoints);
    free(fittedPointsBuffer);
    
    return resultPath;
}
