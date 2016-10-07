#pragma once

#include "ofMain.h"
#include "ofxAndroid.h"
#include "ofxNetwork.h"
<<<<<<< HEAD
<<<<<<< HEAD
#include "ofxAccelerometer.h"
=======
>>>>>>> 96791d33272d9a0bd23bf02ba6b2787c6994f005
=======
>>>>>>> faae088f9b08b1efeb0d1ac07caeae47f024ee46

class arcPoint {
public:
    float position;
    ofColor fill;
};


class ofApp : public ofxAndroidApp{
	
	public:
		
		void setup();
		void update();
		void draw();
		
		void keyPressed(int key);
		void keyReleased(int key);
		void windowResized(int w, int h);

		void touchDown(int x, int y, int id);
		void touchMoved(int x, int y, int id);
		void touchUp(int x, int y, int id);
		void touchDoubleTap(int x, int y, int id);
		void touchCancelled(int x, int y, int id);
		void swipe(ofxAndroidSwipeDir swipeDir, int id);

		void pause();
		void stop();
		void resume();
		void reloadTextures();

		bool backPressed();
		void okPressed();
		void cancelPressed();


	    int left, right;
	    ofxUDPManager client;

	    bool connected;

	    float speed;
	    bool updateFlag;

	    ofPolyline arc;
	    deque<arcPoint> arcPoints;

	    ofMesh mesh;
	    ofImage carIcon;

	    ofVec3f accel;
	    string udpMessage;

};
