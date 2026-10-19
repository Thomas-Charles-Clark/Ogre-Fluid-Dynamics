#include "Leap/LeapSystem.h"
#include "Leap/LeapSystemState.h"
#include "OgrePrerequisites.h"
#include "OgreVector3.h"
//
//#include <Windows.h>
//#include <iostream>
//#include <sstream>
//
//void DBOut(const WCHAR* s)
//{
//    std::wostringstream os_;
//    os_ << s << std::endl;
//    OutputDebugStringW(os_.str().c_str());
//}

namespace MyThirdOgre
{
    LeapSystem::LeapSystem(GameState* gameState) :
        BaseSystem(gameState),
        mConnectionHandle(0),
        mPreviousTrackingMessage(LEAP_CONNECTION_MESSAGE()),
        mRunning(false),
        mVelocityScalingFactor(1.0f),
        mPositionScalingFactor(5.0f)
    {

    }

    //-----------------------------------------------------------------------------------
    LeapSystem::~LeapSystem(void) {

    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::initialize(void) {
        createLeapConnection();
    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::deinitialize(void) {
        destroyLeapConnection();
    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::createLeapConnection(void) {
        eLeapRS result = LeapCreateConnection(NULL, &mConnectionHandle);
        if (result == eLeapRS_Success) {
            result = LeapOpenConnection(mConnectionHandle);
            if (result == eLeapRS_Success) {
                mRunning = true;
                pollConnection(0.0f);
            }
        }
    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::destroyLeapConnection(void) {
        if (mConnectionHandle) {
            mRunning = false;
            LeapDestroyConnection(mConnectionHandle);
            mConnectionHandle = 0;
        }
    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::pollConnection(float timeSinceLast) {
        if (mRunning) {
            eLeapRS result;
            LEAP_CONNECTION_MESSAGE msg;

            result = LeapPollConnection(mConnectionHandle, 0, &msg);
            //Handle message

            switch (msg.type) {
            case eLeapEventType_Tracking: 
                {
                    if (msg.tracking_event->nHands >= 1)
                    {
                        Ogre::Vector3 vVel = Ogre::Vector3(msg.tracking_event->pHands[0].palm.velocity.v);
                     
                        Ogre::Vector3 vPos = Ogre::Vector3(msg.tracking_event->pHands[0].palm.position.v);

                        vPos /= mPositionScalingFactor;


#if OGRE_DEBUG_MODE == OGRE_DEBUG_LEVEL_DEBUG && FIELD_DEBUG_MODE == FIELD_DEBUG_MODE_TRUE
                        vPos.y -= 50.0f;
#else
                        vPos.y = 0.0f;
#endif
                        
                        vVel *= mVelocityScalingFactor;

                        bool anyFingerExtended = true;
                        
                        anyFingerExtended = msg.tracking_event->pHands[0].index.is_extended
                            || msg.tracking_event->pHands[0].middle.is_extended
                            || msg.tracking_event->pHands[0].ring.is_extended
                            || msg.tracking_event->pHands[0].pinky.is_extended;

#if OGRE_DEBUG_MODE == OGRE_DEBUG_LEVEL_DEBUG && FIELD_DEBUG_MODE == FIELD_DEBUG_MODE_TRUE
                        Leap_MotionMessage vMsg = Leap_MotionMessage(timeSinceLast, vVel, vPos, anyFingerExtended ? 25.0f : -25.0f);
#else
                        Leap_MotionMessage vMsg = Leap_MotionMessage(timeSinceLast, vVel, vPos, anyFingerExtended ? 50.0f : -50.0f);
#endif

                        //Leap_MotionMessage vMsg = Leap_MotionMessage(timeSinceLast, vVel, vPos, 10.0f);

                        this->queueSendMessage(mLogicSystem, Mq::LEAPFRAME_MOTION, vMsg);

                        mPreviousTrackingMessage = msg;
                    }
                }
                break;
            }
        }
    }
    
    //-----------------------------------------------------------------------------------
    void LeapSystem::processIncomingMessage(Mq::MessageId messageId, const void* data)
    {

    }

    //-----------------------------------------------------------------------------------
    void LeapSystem::finishFrameParallel(void)
    {
        //Notify the GraphicsSystem we're done with this frame.
        if (mGraphicsSystem)
        {
            this->queueSendMessage(mGraphicsSystem, Mq::LEAPFRAME_FINISHED, NULL);
        }

        BaseSystem::finishFrameParallel();
    }
}