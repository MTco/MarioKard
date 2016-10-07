//
//  Posts.h
//  MarioCard
//
//  Created by Joshua Noble on 26/7/16.
//
//

#include "ofVec2f.h"
#include "ofRectangle.h"

#pragma once

class Posts {
    
    public:
    
    float pct;
    ofRectangle area;
    float initX, initY;
    float distX, distY;
    float aX, aY;
    
    //const float exponent = 4;   // Determines the curve
    
    ofVec2f dest;
    ofVec2f initVec;
    
    int frame;
    bool remove;
    
    Posts(int x, int y, int areaX, int areaY, float startingPercentage)
    {
        remove = false;
        frame = 0;
        pct = startingPercentage;
        initX = x;
        initY = y;
        initVec.set(initX, 0);
        distX = (areaX/2) - initX;
        distY = areaY - initY;
        //distY = ofGetHeight();
        
        dest.set((areaX/2), areaY);
        
        area.set(x, y, 4, 20);
    };
    
    void update( float exponent, float speed )
    {
        pct += speed;
        area.x = round(initX + (pct * distX));
        float p = pow(pct, exponent);
        area.y = round(initY + (p * distY));
        
        area.setSize( 5, max<float>(6, round( abs(pct) * 30.0)));
        //area.setSize( max<float>(2, round(pct * 10.0)), max<float>(6, round(pct * 10.0)));
        
        if (pct > 1.0 || pct < -1.0)
        {
            remove = true;
        }
    };
    
    void draw()
    {
        
//        ofVec2f pv1[] = {ofVec2f(area.x + (area.width/2), area.y), dest};
//        ofVec2f pv2[] = {ofVec2f(0, area.y + area.height), ofVec2f(ofGetWidth(), area.y + area.height)};
//        
//        ofVec2f intersect1 = intersection(&pv1[0], &pv2[0]);
//        if (intersect1.x != -1 && intersect1.y != -1)
//        {
//            ofSetLineWidth(5);
//            ofDrawLine(area.x - (area.height * 2), area.y, intersect1.x - (area.height * 2), intersect1.y);
//            ofDrawLine(area.x + (area.height * 2), area.y, intersect1.x + (area.height * 2), intersect1.y);
//        }
        
        
        ofDrawRectangle(area.x - (area.height * 2), area.y, area.width, area.height);
        ofDrawRectangle(area.x + (area.height * 2), area.y, area.width, area.height);
        
    };
    
    ofVec2f intersection(ofVec2f *line1, ofVec2f *line2) {
        
        ofVec2f ret(-1, -1);
        
        float d = (line1[0].x - line1[1].x) * (line2[0].y - line2[1].y) - (line1[0].y - line1[1].y) * (line2[0].x - line2[1].x);
        // If d is zero, there is no intersection
        if (d == 0) return ret;
        
        // Get the x and y
        float pre = (line1[0].x*line1[1].y - line1[0].y*line1[1].x), post = (line2[0].x*line2[1].y - line2[0].y*line2[1].x);
        float x = ( pre * (line2[0].x - line2[1].x) - (line1[0].x - line1[1].x) * post ) / d;
        float y = ( pre * (line2[0].y - line2[1].y) - (line1[0].y - line1[1].y) * post ) / d;
        
        // Check if the x and y coordinates are within both lines
        if ( x < min(line1[0].x, line1[1].x) || x > max(line1[0].x, line1[1].x) || x < min(line2[0].x, line2[1].x) || x > max(line2[0].x, line2[1].x) ) {
            return ret;
        }
        
        if ( y < min(line1[0].y, line1[1].y) || y > max(line1[0].y, line1[1].y) || y < min(line2[0].y, line2[1].y) || y > max(line2[0].y, line2[1].y) ) { 
            return ret;
        }
        
        // Return the point of intersection
        
        ret.x = x;
        ret.y = y;
        return ret;
    };
};