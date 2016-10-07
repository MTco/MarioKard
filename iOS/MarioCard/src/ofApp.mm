#include "ofApp.h"

const int frequency = 10;


//--------------------------------------------------------------
void ofApp::setup(){
    connected = false;
    
    // make a web socket connection that we can stream data to
    client.Create();
    client.Connect("192.168.216.158",8000);
    client.SetNonBlocking(true);
    
    switch (ofGetOrientation()) {
        case OF_ORIENTATION_DEFAULT:
            ofSetOrientation(OF_ORIENTATION_90_LEFT);
            break;
        case OF_ORIENTATION_180:
            ofSetOrientation(OF_ORIENTATION_90_LEFT);
            break;
        case OF_ORIENTATION_90_LEFT:
            ofSetOrientation(OF_ORIENTATION_90_LEFT);
            break;
        case OF_ORIENTATION_90_RIGHT:
            ofSetOrientation(OF_ORIENTATION_90_RIGHT);
            break;
        default:
            break;
    }
    
    int count = 0;
    for( float i = 0; i < 1.0; i+=0.05 )
    {
        arcPoint p;
        p.position = i;
        
        if(count % 2)
        {
            p.fill.set(122, 122, 122);
        }
        else
        {
            p.fill.set(255, 255, 255);
        }
        
        arcPoints.push_back(p);
        count++;
    }
    
    left = 0;
    right = 0;
    
    carIcon.load("car2.png");

}

//--------------------------------------------------------------
void ofApp::update(){
    
    // send a message over our socket about our speed & position
    if(ofGetElapsedTimeMillis() % 100 == 0) // 10hz refresh?
    {
        stringstream message;
        // Kart is just listening for 0-255 where 127 = stopped, 0 = full backwards, 255 = full forwards
        message << (left + 255 / 4) << ":" << (right + 255 / 4);
        client.Send(message.str().c_str(), message.str().size());
        updateFlag = false;
    }
    
    // figure out speed and direction from L/R tread
    speed = ofMap( left + right, -254, 254, 0.03, -0.03);
    float steer = ofMap(left - right, -254, 254, 0, ofGetWidth());
    
    // make a brand new arc using our steer
    arc.clear();
    arc.addVertex(steer, 50);
    arc.bezierTo( ofGetWidth()/2 + ((ofGetWidth()/2 - steer) / 4), ofGetHeight()*0.5, ofGetWidth()/2, ofGetHeight()*0.75, ofGetWidth()/2, ofGetHeight(), 100);
    arc.addVertex(ofGetWidth()/2, ofGetHeight());
    
    // accelerate the arc points nicely for point-along-arc calculations
    for( int i = 0; i < arcPoints.size(); i++ )
    {
        arcPoints.at(i).position += speed;
        arcPoints.at(i).position = roundf(arcPoints.at(i).position * 60) / 60.0;
    }
    
    // if the point is off either end of the arc, delete it and add a new one at the beginning or end
    // of the arc so we're continuous
    for( int i = 0; i < arcPoints.size(); i++ )
    {
        
        if(arcPoints.at(i).position < 0.0)
        {
            
            cout << (arcPoints.begin() + i)->fill << endl;
            arcPoints.erase(arcPoints.begin() + i);
            arcPoint p;
            p.position = 1.0;
            if(arcPoints.at(arcPoints.size()-1).fill.r == 122)
            {
                p.fill.set(255, 255, 255);
            }
            else
            {
                p.fill.set(122, 122, 122);
            }
            arcPoints.push_back(p);
        }
        
        if(arcPoints.at(i).position > 1.0)
        {
            cout << (arcPoints.begin() + i)->fill << endl;
            arcPoints.erase(arcPoints.begin() + i);
            arcPoint p;
            p.position = 0.0;
            if(arcPoints.at(0).fill.r == 122)
            {
                p.fill.set(255, 255, 255, 255);
            }
            else
            {
                p.fill.set(122, 122, 122, 255);
            }
            arcPoints.push_front(p);
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    // clear
    ofBackground(0, 0, 0);
    
    ofEnableAlphaBlending();
    ofSetColor(0, 255, 0);
    
    int w = ofGetWidth();
    int h = ofGetHeight();
    
    // draw our controls
    ofDrawRectangle(0, h/2, 50, ofMap(left, -127, 127, -h/2, h/2));
    ofDrawRectangle(w - 50, h/2, 50, ofMap(right, -127, 127, -h/2, h/2));
    
    ofPushMatrix();
    ofTranslate(0, 20);
    ofRotateX(50);
    
    ofSetLineWidth(10);
    
    int scale = 60;
    
    // use our arc segments to draw boxes that are our 'road'
    for( int i = 1; i < arcPoints.size(); i++ )
    {
        
        float position = arcPoints.at(i).position;
        float prevPosition = roundf(arcPoints.at(i-1).position * 60) / 60.0;
        
        ofSetColor(arcPoints.at(i).fill);
        ofBeginShape();
        
        ofVertex(arc.getPointAtPercent(prevPosition).x - scale, arc.getPointAtPercent(prevPosition).y);
        ofVertex(arc.getPointAtPercent(prevPosition).x + scale, arc.getPointAtPercent(prevPosition).y);
        ofVertex(arc.getPointAtPercent(position).x + scale, arc.getPointAtPercent(position).y);
        ofVertex(arc.getPointAtPercent(position).x - scale, arc.getPointAtPercent(position).y);
        
        ofEndShape();
        
    }
    
    ofPopMatrix();
    
    ofSetColor(255, 255, 255);
    carIcon.draw(ofGetWidth()/2, ofGetHeight() - (carIcon.getHeight()/4), carIcon.getWidth()/4, carIcon.getHeight()/4);
}

//--------------------------------------------------------------
void ofApp::exit(){
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    if(touch.x < ofGetWidth()/2)
    {
        left = ofMap(touch.y, 0, ofGetHeight(), -127, 127);
    }
    else
    {
        right = ofMap(touch.y, 0, ofGetHeight(), -127, 127);
    }
    updateFlag = true;
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    if(touch.x < ofGetWidth()/2)
    {
        left = ofMap(touch.y, 0, ofGetHeight(), -127, 127);
    }
    else
    {
        right = ofMap(touch.y, 0, ofGetHeight(), -127, 127);
    }
    
//    if(ofGetFrameNum() % frequency == 0 )
//    {
//        addPost();
//    }
    
    updateFlag = true;
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    
}
