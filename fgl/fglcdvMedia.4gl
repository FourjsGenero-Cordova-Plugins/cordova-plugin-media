#
#       (c) Copyright Four Js 2017. 
#
#                                 Apache License
#                           Version 2.0, January 2004
#
#       https://www.apache.org/licenses/LICENSE-2.0

#+ Genero 4GL wrapper around the Cordova Media plugin.
IMPORT util
IMPORT os
PUBLIC CONSTANT MEDIA_STATE = 1
PUBLIC CONSTANT MEDIA_DURATION = 2
PUBLIC CONSTANT MEDIA_POSITION = 3
PUBLIC CONSTANT MEDIA_ERROR = 9

PUBLIC CONSTANT MEDIA_STATE_NONE = 0
PUBLIC CONSTANT MEDIA_STATE_STARTING = 1
PUBLIC CONSTANT MEDIA_STATE_RUNNING = 2
PUBLIC CONSTANT MEDIA_STATE_PAUSED = 3
PUBLIC CONSTANT MEDIA_STATE_STOPPED = 4
CONSTANT MEDIA_STATE_MSG = '["None", "Starting", "Running", "Paused", "Stopped"]'
CONSTANT CALLWOW="callWithoutWaiting"
CONSTANT _CALL="call"
CONSTANT CDV="cordova"
CONSTANT MEDIA="Media"
DEFINE m_states DYNAMIC ARRAY OF STRING
DEFINE m_hash util.Hash
DEFINE m_statusarr DYNAMIC ARRAY OF util.JSONObject

PUBLIC TYPE StatusT util.JSONObject

PUBLIC TYPE playOptionsT RECORD
  playAudioWhenScreenIsLocked BOOLEAN,
  numberOfLoops INT
END RECORD

#helper to avoid the need to define this record in user code if there is just one player
PUBLIC DEFINE playOptions playOptionsT

#+ inits the plugin
#+ must be called prior other calls
PUBLIC FUNCTION init()
  DEFINE s STRING
  LET m_hash=util.Hash.create(s)
  CALL util.JSON.parse(MEDIA_STATE_MSG,m_states)
  CALL messageChannel()
END FUNCTION

#+ Returns a string description for a messageType
#+ @param messageType can be one of MEDIA_STATE, MEDIA_DURATION,MEDIA_POSITION,MEDIA_ERROR
#+ @returnType STRING
#+ @return "MEDIA_STATE", "MEDIA_DURATION", "MEDIA_POSITION", Or "MEDIA_ERROR"
PUBLIC FUNCTION messageType2String(messageType INT) RETURNS STRING
  CASE messageType
    WHEN MEDIA_STATE RETURN "MEDIA_STATE"
    WHEN MEDIA_DURATION RETURN "MEDIA_DURATION"
    WHEN MEDIA_POSITION RETURN "MEDIA_POSITION"
    WHEN MEDIA_ERROR RETURN "MEDIA_ERROR"
  END CASE
  RETURN "Unknown"
END FUNCTION

#+ Returns a string description for a media state.
#+ @param state can be one of: MEDIA_STATE_NONE, MEDIA_STATE_STARTING,
#+ MEDIA_STATE_RUNNING,MEDIA_STATE_PAUSED, MEDIA_STATE_STOPPED
#+ @returnType STRING
#+ @return "None", "Starting", "Running", "Paused", Or "Stopped"
PUBLIC FUNCTION mediaState2String(state INT) RETURNS STRING
  LET state=state+1 --4GL starts with 1
  IF state>=1 AND state<=m_states.getLength() THEN
    RETURN m_states[state]
  END IF
  RETURN "Unknown"
END FUNCTION

#+ Registers pushing cordova callbacks into the current dialog
PRIVATE FUNCTION messageChannel()
  CALL ui.interface.frontcall(CDV,CALLWOW, [MEDIA,"messageChannel"],[])
END FUNCTION

#+ Registers a fileName for a soundId to be used in several calls.
#+ For the most applications its sufficient to create exactly one soundId.
#+ Only if multiple audio sources need to be played simultaneously, multiple
#+ soundId's are needed.
#+ @param soundId to be used in startXXAudio, stopXXAudio etc
#+ @param filename file for playing or recording
#+ one and the same soundId can be used for recording and playing if recording and playing is done exclusively
#+ the parameter can also be an http(s) URL for playing
PUBLIC FUNCTION create(soundId STRING,filename STRING)
  CALL m_hash.put(soundId,filename)
  --we must not call create if the file does not yet exist (GMI)
  IF os.Path.exists(filename) OR filename.getIndexOf("http",1)==1 THEN
    CALL ui.interface.frontcall(CDV,_CALL, [MEDIA,"create",soundId,fileName],[])
  END IF
END FUNCTION

#+ releases resources associated with a soundId (filename,players,internal recording buffers)
#+ @param soundId must have been created before
PUBLIC FUNCTION release(soundId STRING)
  DEFINE method STRING
  --Android: returns a result, IOS: does not return a result
  LET method=IIF(ui.Interface.getFrontEndName()=="GMA",_CALL,CALLWOW)
  CALL ui.interface.frontcall(CDV,method, [MEDIA,"release",soundId],[])
  CALL m_hash.remove(soundId)
END FUNCTION

#+ starts playing a sound file
#+ if the playback is over, a cordovacallback is triggered
#+ the file for playback must have been registered with the create call
#+ it must exist and can have several
#+ extensions depending on the platform
#+ @param soundId registered with the "create" call
#+ @param playOptions see playOptionsT
PUBLIC FUNCTION startPlayingAudio(soundId STRING,playOptions playOptionsT)
  DEFINE fileName STRING
  CALL m_hash.get(soundId,filename)
  CALL ui.interface.frontcall(CDV,CALLWOW,
        [MEDIA,"startPlayingAudio",soundId
        ,fileName,playOptions],[])
END FUNCTION

#+ Pauses playing audio.
#+ Causes a cordovacallback about state change.
#+ Resume playing with startPlayingAudio (in opposite to resumeRecordingAudio).
#+ @param soundId references the sound started with startPlayingAudio
PUBLIC FUNCTION pausePlayingAudio(soundId STRING)
  CALL ui.interface.frontcall(CDV,CALLWOW,
                [MEDIA,"pausePlayingAudio",soundId],[])
END FUNCTION

#+ Stops playing audio.
#+ Causes a cordovacallback about state change.
#+ @param soundId references the sound started with startPlayingAudio
PUBLIC FUNCTION stopPlayingAudio(soundId STRING)
  CALL ui.interface.frontcall(CDV,CALLWOW,
        [MEDIA,"stopPlayingAudio",soundId],[])
END FUNCTION

#+ Starts recording to file.
#+ Possible extensions on IOS: .wav and .mp4 , on Android: .mp3 and .aac .
#+ The recording file name was specified using the create() call.
#+ In case it exists it will be overwritten. 
#+ The directory for the file must exist.
#+ Causes a cordovacallback about state change.
#+ @param soundId unique identfier to reference the recording sound later on
PUBLIC FUNCTION startRecordingAudio(soundId STRING)
  DEFINE filename STRING
  CALL m_hash.get(soundId,filename)
  CALL ui.interface.frontcall(CDV,CALLWOW,
           [MEDIA,"startRecordingAudio",soundId,fileName],[])  
END FUNCTION

#+ Stops recording.
#+ Causes a cordovacallback about state change.
#+ @param soundId id used to start the recording
PUBLIC FUNCTION stopRecordingAudio(soundId STRING)
  DISPLAY "stopRecording"
  CALL ui.interface.frontcall(CDV,CALLWOW,
           [MEDIA,"stopRecordingAudio",soundId],[])  
END FUNCTION

#+ Pauses recording.
#+ Resume recording with resumeRecordingAudio().
#+ Causes a cordovacallback about state change.
#+ @param soundId id used to start the recording
PUBLIC FUNCTION pauseRecordingAudio(soundId STRING)
  CALL ui.interface.frontcall(CDV,CALLWOW,
          [MEDIA,"pauseRecordingAudio",soundId],[])
END FUNCTION 

#+ Resumes recording.
#+ Causes a cordovacallback about state change.
#+ @param soundId id used to start the recording
PUBLIC FUNCTION resumeRecordingAudio(soundId STRING)
  CALL ui.interface.frontcall(CDV,CALLWOW,
          [MEDIA,"resumeRecordingAudio",soundId],[])
END FUNCTION

#+ Does only work while playing a sound file, not while recording.
#+ @return the elapsed time
#+ @param soundId id used to start the playback
PUBLIC FUNCTION getCurrentPositionAudio(soundId STRING) RETURNS FLOAT
   DEFINE position FLOAT
   CALL ui.interface.frontcall(CDV,_CALL,
         [MEDIA,"getCurrentPositionAudio",soundId],[position])
   DISPLAY "position:",position
   RETURN position
END FUNCTION

#+ Returns the Audio Meter level when recording.
#+ @return a normalized value between 0.0 and 1.0
#+ @param soundId id used to start the recording
PUBLIC FUNCTION getCurrentAmplitudeAudio(soundId STRING) RETURNS FLOAT
   DEFINE amplitude FLOAT 
   CALL ui.Interface.frontCall(CDV,_CALL,
     [Media,"getCurrentAmplitudeAudio",soundId],[amplitude])
   RETURN amplitude
END FUNCTION

#+ Sets the audio volume.
#+ @param soundId id used to start the playback
#+ @param volume range 0.0 to 1.0
PUBLIC FUNCTION setVolume(soundId STRING,volume FLOAT) 
   CALL ui.Interface.frontCall(CDV,CALLWOW,
     [Media,"setVolume",soundId,volume],[])
END FUNCTION

#+ Sets the playback rate: only available in IOS.
#+ @param soundId id used to start the playback
#+ @param rate range 0.0 to 1.0
PUBLIC FUNCTION setRate(soundId STRING,rate FLOAT) 
   IF ui.Interface.getFrontEndName()=="GMI" THEN
     CALL ui.Interface.frontCall(CDV,CALLWOW,
       [Media,"setRate",soundId,rate],[])
   END IF
END FUNCTION

#+ Seeks to a position in the audio stream.
#+ Only available for playback.
#+ May causes a cordovacallback about state change.
#+ @param soundId id used to start the playback
#+ @param position milliseconds since start
PUBLIC FUNCTION seekToAudio(soundId STRING,position INT) 
   CALL ui.Interface.frontCall(CDV,CALLWOW,
       [Media,"seekToAudio",soundId,position],[])
END FUNCTION

#+ Returns the duration for a media id, this works only if the file exists
#+ and is playable
#+ @param soundId id registered with the @see create() function with an existing file name
#+ @return duration of the file
PUBLIC FUNCTION getDurationAudio(soundId STRING) RETURNS FLOAT
  DEFINE fileName STRING
  DEFINE duration FLOAT
  CALL m_hash.get(soundId,filename)
  CALL ui.Interface.frontCall(CDV,_CALL,
       [Media,"getDurationAudio",soundId,filename],[duration])
  RETURN duration
END FUNCTION

#+ Handles *all* media events in response to an ON ACTION cordovacallback and queues media status messages internally.
#+ Those status messages can be fetched with getNextStatus()
#+
#+ @code
#+ ON ACTION cordovacallback
#+   CALL fglcdvMedia.handleCallback()
#+   WHILE (mediastatus:=fglcdv.getNextStatus()) IS NOT NULL
#+     --do things with the status objects
PUBLIC FUNCTION handleCallback()
   DEFINE result STRING
   CALL ui.Interface.frontCall(CDV,"getAllCallbackData",
     ["Media-"],[result])
   --DISPLAY "fglcdvMedia.handleCallback:",result
   CALL parseJSON(result)
END FUNCTION

PRIVATE FUNCTION parseJSON(result STRING)
  DEFINE arr util.JSONArray
  DEFINE obj,mstatus util.JSONObject
  DEFINE i INT
  LET arr=util.JSONArray.parse(result)
  FOR i=1 TO arr.getLength() --we just append the status objects
    LET obj=arr.get(i)
    LET mstatus=obj.get("status")
    IF mstatus IS NOT NULL THEN
      LET m_statusarr[m_statusarr.getLength()+1]=mstatus
    END IF
  END FOR
END FUNCTION

#+ Returns how many status objects have been queued
#+ @returnType INT
#+ @return count of objects
PUBLIC FUNCTION getStatusCount() RETURNS INT
  RETURN m_statusarr.getLength()
END FUNCTION

#+ Returns the next queued status object and removes it from the internal queue.
#+ This object must be passed to the xxFromStatus functions
#+ @return a status object (it can be treated as a kind of opaque handle, you should never access it directly)
#+
#+ @code
#+ WHILE (mediaStatus:=getNextStatus()) IS NOT NULL
#+   LET messageType=fglcdvMedia.getMessageTypeFromStatus(mediaStatus)
#+   LET mediaId=fglcdvMedia.getMediaIdFromStatus(mediaStatus)
#+   CASE messageType
#+     WHEN fglcdvMedia.MEDIA_STATE
#+       LET state=fglcdvMedia.getStateFromStatus(mediaStatus)
#+     WHEN fglcdvMedia.MEDIA_DURATION
#+       LET duration=fglcdvMedia.getDurationFromStatus(mediaStatus)
#+     WHEN fglcdvMedia.MEDIA_POSITION
#+       LET position=fglcdvMedia.getPositionFromStatus(mediaStatus)
#+     WHEN fglcdvMedia.MEDIA_ERROR
#+       CALL fglcdvMedia.getErrorFromStatus(mediaStatus) RETURNING code,message
#+ END WHILE
PUBLIC FUNCTION getNextStatus() RETURNS StatusT
  DEFINE st util.JSONObject
  IF m_statusarr.getLength()==0 THEN
    RETURN NULL
  END IF
  LET st=m_statusarr[1]
  CALL m_statusarr.deleteElement(1)
  RETURN st
END FUNCTION

#+ Returns a message type out of the given mediaStatus
#+ @return MEDIA_STATE,MEDIA_DURATION,MEDIA_POSITION or MEDIA_ERROR
#+
#+ @param mediaStatus (pass the return value of getNextStatus())
PUBLIC FUNCTION getMessageTypeFromStatus(mediaStatus StatusT) RETURNS INT
  DEFINE msgType INT
  LET msgType=mediaStatus.get("msgType")
  RETURN msgType
END FUNCTION

#+ Returns the mediaId causing the status event
#+ @return a mediaId used for recording of playing
#+ @param mediaStatus (pass the return value of getNextStatus())
PUBLIC FUNCTION getMediaIdFromStatus(mediaStatus StatusT) RETURNS STRING
  RETURN mediaStatus.get("id")
END FUNCTION

#+ Returns the media state when the status message type is MEDIA_STATE.
#+ @return  MEDIA_STATE_NONE,MEDIA_STATE_STARTING,MEDIA_STATE_RUNNING, MEDIA_STATE_PAUSED,MEDIA_STATE_STOPPED
#+ @param mediaStatus (pass the return value of getNextStatus())
PUBLIC FUNCTION getStateFromStatus(mediaStatus StatusT) RETURNS INT
  DEFINE state INT
  LET state=mediaStatus.get("value")
  DISPLAY "media state:",mediaState2String(state)
  RETURN state
END FUNCTION

#+ Returns the duration when the status message type is MEDIA_DURATION.
#+ @return returns a duration out of the given mediaStatus
#+ @param mediaStatus (pass the return value of getNextStatus())
PUBLIC FUNCTION getDurationFromStatus(mediaStatus StatusT) RETURNS FLOAT
  DEFINE duration FLOAT 
  -- for ex. { "status": { "msgType":2 ,"value":4.0 }}
  LET duration=mediaStatus.get("value")
  DISPLAY sfmt("duration:%1",duration)
  RETURN duration
END FUNCTION

#+ Returns the media position out of the given mediaStatus 
#+ when the status message type is MEDIA_POSITION.
#+ @return returns a media position out of the given mediaStatus
#+ @param mediaStatus (pass the return value of getNextStatus())
PUBLIC FUNCTION getPositionFromStatus(mediaStatus StatusT) RETURNS FLOAT
  DEFINE position FLOAT 
  -- for ex. { "status": { "msgType":3 ,"value":0.0 }}
  LET position=mediaStatus.get("value")
  RETURN position
END FUNCTION

#+ Returns the error code and error message 
#+ when the status message type is MEDIA_ERROR.
#+ @return an error code and an error message
#+ @param mediaStatus pass the return value of getNextStatus()
PUBLIC FUNCTION getErrorFromStatus(mediaStatus util.JSONObject) RETURNS INT,STRING
  DEFINE err util.JSONObject
  DEFINE code INT
  DEFINE message STRING
  -- for ex. { "status": { "msgType":9 ,"value":{ "message":"someErr",code:5 }}}
  LET err=mediaStatus.get("value")
  LET message=err.get("message")
  LET code=err.get("code")
  RETURN code,message
END FUNCTION

#+ Returns an array containing valid file extensions for recording
#+ @return ["aac"] for GMA and ["wav","m4a"] for GMI
PUBLIC FUNCTION getRecordingExtensions() RETURNS DYNAMIC ARRAY OF STRING
  DEFINE exts DYNAMIC ARRAY OF STRING
  CASE ui.Interface.getFrontEndName()
    WHEN "GMI" 
      LET exts[1]="wav"
      LET exts[2]="m4a"
    WHEN "GMA" 
      LET exts[1]="aac"
  END CASE
  RETURN exts
END FUNCTION

#+ Returns if a a give file extension is a valid extension for recording
#+ @param extension extension such as "m4a" or "aac"
#+ @return TRUE if the extension is usable for recording, FALSE otherwise
PUBLIC FUNCTION isValidRecordingExtension(extension STRING) RETURNS BOOLEAN
   DEFINE validExtensions DYNAMIC ARRAY OF STRING
   LET validExtensions=getRecordingExtensions()
   RETURN validExtensions.search("*",extension)<>0 
END FUNCTION
