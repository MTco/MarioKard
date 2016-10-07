#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){	

    
    coreMotion.setupMagnetometer();
    coreMotion.setupGyroscope();
    coreMotion.setupAccelerometer();
    coreMotion.setupAttitude(CMAttitudeReferenceFrameXMagneticNorthZVertical);
    
    connected = false;
    
    // make a udp connection that we can stream data to
    client.Create();
    client.Connect("192.168.42.1",3000);
    client.SetNonBlocking(true);
    
    // now register
    string regStr = "register_control";
    client.Send("register_control", regStr.size());
    
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
    
    coreMotion.resetAttitude();
}

//--------------------------------------------------------------
void ofApp::update(){
    coreMotion.update();
    
    left = ofMap(coreMotion.getPitch(), -1.4, 1.4, -127, 127);
    right = ofMap(coreMotion.getPitch(), -1.4, 1.4, 127, -127);
    
    // figure out speed and direction from L/R tread
    //speed = ofMap( left + right, -254, 254, 0.03, -0.03);
    float steer = ofMap(left - right, -254, 254, 0, ofGetWidth());
    
    // send a message over our socket about our speed & position
    if(ofGetFrameNum() % 5 == 0) // 10hz refresh?
    {
        
        float trueSteer = left - right;
        
        int leftTread = 90 * speed;
        int rightTread = 90 * speed;
        
        if(speed > 0.0)
        {
        
            // all the way to the left will be -254, so slow left tread to we steer to left
            leftTread -= ofMap(trueSteer, -254, 254, 20, -20);
            // all the way to the right will be 254, so slow right tread to we steer to right
            rightTread -= ofMap(trueSteer, -254, 254, -20, 20);
        }
        else
        {
            // all the way to the left will be -254, so slow left tread to we steer to left
            leftTread += ofMap(trueSteer, -254, 254, 20, -20);
            // all the way to the right will be 254, so slow right tread to we steer to right
            rightTread += ofMap(trueSteer, -254, 254, -20, 20);
        }
        
        // Kart is just listening for 0-255 where 127 = stopped, 0 = full backwards, 255 = full forwards
        stringstream message;
        message << "speed:" << min(255, max(0, (leftTread + 127))) << ":" << min(255, max(0, (rightTread + 127)));
        cout << message.str() << endl;
        udpMessage = message.str();
        client.Send(message.str().c_str(), message.str().size());
    }
    
    // make a brand new arc using our steer
    arc.clear();
    arc.addVertex(steer, 50);
    arc.bezierTo( ofGetWidth()/2 + ((ofGetWidth()/2 - steer) / 4), ofGetHeight()*0.5, ofGetWidth()/2, ofGetHeight()*0.75, ofGetWidth()/2, ofGetHeight(), 100);
    arc.addVertex(ofGetWidth()/2, ofGetHeight());
    
    // accelerate the arc points nicely for point-along-arc calculations
    for( int i = 0; i < arcPoints.size(); i++ )
    {
        arcPoints.at(i).position += speed * 0.03;
        arcPoints.at(i).position = roundf(arcPoints.at(i).position * 60) / 60.0;
    }
    
    // if the point is off either end of the arc, delete it and add a new one at the beginning or end
    // of the arc so we're continuous
    for( int i = 0; i < arcPoints.size(); i++ )
    {
        
        if(arcPoints.at(i).position < 0.0)
        {
            
            //cout << (arcPoints.begin() + i)->fill << endl;
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
            //cout << (arcPoints.begin() + i)->fill << endl;
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
    carIcon.draw(ofGetWidth()/2 - (carIcon.getWidth()/8), ofGetHeight() - (carIcon.getHeight()/4) - 20, carIcon.getWidth()/4, carIcon.getHeight()/4);
    
    stringstream ss;
    ss <<  left << " " << right;
    
    ofDrawBitmapString(ss.str(), 30, 30);
    ofDrawBitmapString(udpMessage, 30, 50);
    
//    ofSetColor(255, 255, 0);
//    ofDrawBitmapString(ofToString(coreMotion.getRoll(),3), 20, 100);
//    ofDrawBitmapString(ofToString(coreMotion.getPitch(),3), 120, 100);
//    ofDrawBitmapString(ofToString(coreMotion.getYaw(),3), 220, 100);

}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    speed = ofMap(touch.y, 0, ofGetHeight(), 1, -1);
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    speed = ofMap(touch.y, 0, ofGetHeight(), 1, -1); // used to be 0.03 to -0.03
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
