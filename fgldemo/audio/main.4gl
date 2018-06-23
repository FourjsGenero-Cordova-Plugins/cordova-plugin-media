# Property of Four Js*
# (c) Copyright Four Js 2017, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these
# samples are accurate and suitable for your purposes. Their inclusion is
# purely for information purposes only.

# Cordova audio recorder demo, using the fglcdvMedia module
# you can bundle it on the device, then simple voice recording is available
# if using in remote mode together with gmiclient you can pass a file name or 
# an http URL as argument to main
# fglrun main animals115.mp3

IMPORT util
IMPORT os
IMPORT FGL fgldialog
IMPORT FGL fglcdvMedia

DEFINE m_duration FLOAT
DEFINE m_position FLOAT
DEFINE m_state INT
DEFINE m_FastTimer STRING
DEFINE m_IsRecording BOOLEAN
&define DISPLAY_AT(pos) displayPosition(pos,__LINE__)
CONSTANT SOUNDID="recsound"


MAIN
  DEFINE isPlaying,isPaused,
     playFromCommandLine,seekOnPlay,validRecExt BOOLEAN
  DEFINE recname,extension STRING
  DEFINE recduration INTERVAL MINUTE TO SECOND
  DEFINE fduration,prevpos DOUBLE PRECISION
  DEFINE starttime DATETIME HOUR TO SECOND
  DEFINE slider,prevState INT

  LET int_flag=FALSE
  CALL fglcdvMedia.initialize()

  OPEN FORM f FROM "main"
  DISPLAY FORM f
  INPUT BY NAME slider ATTRIBUTE(UNBUFFERED,ACCEPT=FALSE)
    BEFORE INPUT
        LET m_duration=NULL
        CALL computeFilename() RETURNING recname,playFromCommandLine
        LET extension=os.Path.extension(recname)
        LET validRecExt=fglcdvMedia.isValidRecordingExtension(extension)
        CALL hideElement("record",NOT validRecExt)
        CALL fgl_setTitle(os.Path.baseName(recname))
        CALL dialog.setActionActive("play",IIF(playFromCommandLine,1,0))
        CALL dialog.setActionActive("pause",0)
        CALL dialog.setActionActive("stop",0)
        CALL dialog.setActionActive("cancel",1)
        CALL fglcdvMedia.create(SOUNDID,recname)
        IF playFromCommandLine THEN
          LET fduration=fglcdvMedia.getDurationAudio(SOUNDID)
          IF fduration>0 THEN 
            LET m_duration=fduration
            LET recduration=m_duration UNITS SECOND
            DISPLAY recduration TO duration
            CALL DISPLAY_AT(0.0)
          END IF
        END IF

    ON ACTION record 
        LET m_duration=NULL
        --re create the sound id to avoid cache mismatches on the native side
        CALL fglcdvMedia.release(SOUNDID)
        CALL fglcdvMedia.create(SOUNDID,recname)
        CALL fglcdvMedia.startRecordingAudio(SOUNDID)
        CALL dialog.setActionActive("record",0)
        CALL hideElement("record",TRUE)
        CALL hideElement("record_on",FALSE)
        CALL dialog.setActionActive("play",0)
        CALL dialog.setActionActive("pause",1)
        CALL dialog.setActionActive("cancel",0)
        LET recduration = 0 UNITS SECOND
        LET m_IsRecording=TRUE
        LET starttime=CURRENT
    ON ACTION record_on --pressing on a tape recorders sunken record button does not cause anything
                        --except broken fingers:-)
    ON ACTION pause
        LET recduration=(CURRENT-starttime)
        IF m_IsRecording THEN
          CALL fglcdvMedia.pauseRecordingAudio(SOUNDID)
        ELSE
          CALL fglcdvMedia.pausePlayingAudio(SOUNDID)
        END IF
        CALL hideElement("pause",TRUE)
        CALL hideElement("pause_on",FALSE)
        LET isPaused=TRUE
    ON ACTION pause_on
LABEL continue_after_pause:
        LET starttime=CURRENT-recduration
        IF m_IsRecording THEN
          CALL fglcdvMedia.resumeRecordingAudio(SOUNDID)
        ELSE
          LET seekOnPlay=startPlay(slider,seekOnPlay)
        END IF
LABEL toggle_pause_back:
        CALL hideElement("pause",FALSE)
        CALL hideElement("pause_on",TRUE)
        LET isPaused=FALSE
    ON TIMER 1
        IF m_IsRecording AND NOT isPaused AND m_state==MEDIA_STATE_RUNNING THEN --unfortunately we can't query the position while recording
          LET recduration=(CURRENT-starttime)
          LET fduration=interval2Float(recduration)
          DISPLAY "recduration:",recduration,",fduration:",fduration
          DISPLAY recduration TO duration
          CALL DISPLAY_AT(fduration) --DISPLAY recduration TO at
        END IF
        IF (isPlaying OR (m_duration IS NOT NULL AND m_duration>0)) 
           AND NOT seekOnPlay THEN
          LET slider=getMediaPosition(slider)
        END IF
    ON ACTION stop ATTRIBUTES(TEXT="Media stoprecord",IMAGE="fa-stop",COMMENT="Stops recording")
        --stop does not hand back a plugin result on IOS, therefore we must use
        --"callWithoutWaiting"
        IF m_IsRecording THEN
          CALL fglcdvMedia.stopRecordingAudio(SOUNDID)
        ELSE
          CALL fglcdvMedia.stopPlayingAudio(SOUNDID)
        END IF
        LET slider=0
        CALL DISPLAY_AT(0.0)
        LET seekOnPlay=FALSE
        IF m_IsRecording THEN 
          LET recduration=CURRENT-starttime
          DISPLAY recduration TO duration
          CALL DISPLAY_AT(0.0)
          CALL hideElement("record",FALSE)
          CALL hideElement("record_on",TRUE)
        END IF
        LET m_IsRecording=FALSE
        CALL setActionsOnStop(DIALOG)
        IF isPaused THEN
          GOTO toggle_pause_back
        END IF
        --don't set isPlaying to FALSE here, its set by the callback

    ON ACTION play_on
        GOTO play_action
    ON ACTION play ATTRIBUTES(TEXT="Play Recorded",IMAGE="fa-play",COMMENT="Plays the recorded sound")
LABEL play_action:
        IF m_IsRecording THEN CONTINUE INPUT END IF
        IF isPaused THEN --we do continue also but need to update the pause buttons
          GOTO continue_after_pause 
        END IF
        LET fglcdvMedia.playOptions.playAudioWhenScreenIsLocked=TRUE
        LET fglcdvMedia.playOptions.numberOfLoops=1
        LET seekOnPlay=startPlay(slider,seekOnPlay)
        LET isPlaying=TRUE
        CALL hideElement("play",TRUE)
        CALL hideElement("play_on",FALSE)
        CALL dialog.setActionActive("pause",1)
        CALL dialog.setActionActive("stop",1)
        CALL dialog.setActionActive("record",0)
        CALL dialog.setActionActive("cancel",0)
    ON CHANGE slider
        DISPLAY sfmt("ON CHANGE slider:%1,m_duration:%2",slider,m_duration)
        IF isPlaying AND NOT isPaused THEN
          CALL seek(slider)
        ELSE
          IF m_IsRecording THEN
            LET slider=0
          ELSE
            LET seekOnPlay=TRUE
            CALL displayPositionFromSlider(slider)
          END IF
        END IF
    ON ACTION cordovacallback ATTRIBUTE(DEFAULTVIEW=NO)
        LET prevState=m_State
        LET prevpos=m_position
        CALL processCallback()
        IF isPlaying THEN 
           IF m_duration <> fduration THEN
             --while processing the callbacks we got the true file duration
             LET fduration=m_duration
             LET recduration=m_duration UNITS SECOND
             DISPLAY recduration TO duration
            END IF
        END IF
        IF prevpos<>m_position AND m_position>=0 AND NOT seekOnPlay THEN
            CALL DISPLAY_AT(m_position)
        END IF
        CASE m_state
          WHEN MEDIA_STATE_STOPPED
            IF isPlaying THEN
              LET slider=0
              CALL DISPLAY_AT(0.0)
              CALL setActionsOnStop(DIALOG)
            END IF
            LET isPlaying=FALSE
          WHEN MEDIA_STATE_RUNNING
            CALL dialog.setActionActive("stop",1)
            IF prevState<>m_state AND m_IsRecording AND 
              prevState<>MEDIA_STATE_PAUSED THEN
              LET starttime=CURRENT
              TRY
              --we start a fast timer with 20 callbacks per sec
              CALL ui.interface.frontcall("cordova","callWithoutWaiting", ["GeneroTestPlugin","startBgTimer",0.05],[m_FastTimer])
              CATCH
                DISPLAY "GeneroTestPlugin not found"
              END TRY
            END IF
        END CASE
  END INPUT
  CALL fglcdvMedia.release(SOUNDID)
  CALL fglcdvMedia.finalize()
END MAIN

FUNCTION seek(slider INT)
  DEFINE seekpos FLOAT
  --DISPLAY sfmt("seek slider:%1,m_duration:%2",slider,m_duration)
  IF slider IS NOT NULL AND m_duration IS NOT NULL AND m_duration>0.0 THEN
     LET seekpos=(slider*m_duration)/100.0
     CALL fglcdvMedia.seekToAudio(SOUNDID,seekpos*1000)
  END IF
END FUNCTION 

FUNCTION startPlay(slider INT,seekOnPlay BOOLEAN)
  LET fglcdvMedia.playOptions.playAudioWhenScreenIsLocked=TRUE
  LET fglcdvMedia.playOptions.numberOfLoops=1
  CALL fglcdvMedia.startPlayingAudio(SOUNDID,fglcdvMedia.playOptions.*)
  IF seekOnPlay THEN
    CALL seek(slider)
  END IF
  RETURN FALSE
END FUNCTION      

FUNCTION computeFilename()
  DEFINE extension,fname,recname,path,datadir STRING
  DEFINE play BOOLEAN
  LET extension=IIF(ui.Interface.getFrontEndName()=="GMI","m4a","aac")
  CALL ui.interface.frontcall("standard", "feinfo", ["datadirectory"], [datadir])
  LET path=IIF(base.Application.isMobile(),os.Path.pwd(),datadir)
  LET recname=os.Path.join(path,"Recording."||extension)
  --if we are running remote we can pass an argument for a sound file
  IF NOT base.Application.isMobile() THEN
    IF num_args()>0 THEN
      LET fname=arg_val(1)
      IF fname.getIndexOf("http://",1)==1 OR fname.getIndexOf("https://",1)==1 THEN
        LET recname=fname --play an URL
      ELSE
        --need to transfer the sound file
        LET recname=os.Path.join(datadir,os.Path.baseName(fname))
        CALL fgl_putfile(arg_val(1),recname)
      END IF
      DISPLAY "recname:",recname
      LET play=TRUE
    END IF
  END IF
  RETURN recname,play
END FUNCTION

--force converting the given interval first to seconds
FUNCTION interval2Float(iconv)
  DEFINE iconv INTERVAL SECOND(9) TO SECOND
  DEFINE f DOUBLE PRECISION
  --now this is the trick to removethe seconds
  LET f=iconv / 1 UNITS SECOND
  RETURN f
END FUNCTION

FUNCTION setActionsOnStop(d)
  DEFINE d ui.Dialog
  CALL d.setActionActive("stop",0)
  CALL d.setActionActive("pause",0)
  CALL d.setActionActive("record",1)
  CALL d.setActionActive("play",1)
  CALL d.setActionActive("cancel",1)
  CALL hideElement("play",FALSE)
  CALL hideElement("play_on",TRUE)
  TRY
    CALL ui.Interface.frontCall("cordova","callWithoutWaiting", ["GeneroTestPlugin","stopBgTimer"],[])
    LET m_FastTimer=NULL
    DISPLAY 0 TO meter
  CATCH 
    DISPLAY "ERROR:",err_get(status)
  END TRY
END FUNCTION

FUNCTION hideElement(name,hide)
  DEFINE name STRING
  DEFINE hide BOOLEAN
  DEFINE w ui.Window
  DEFINE f ui.Form
  LET w=ui.Window.getCurrent()
  LET f=w.getForm()
  CALL f.setElementHidden(name,IIF(hide,1,0))
END FUNCTION

FUNCTION displayPosition(position FLOAT,line INT)
  DEFINE at INTERVAL MINUTE TO SECOND
  DISPLAY sfmt("displayPosition '%1' line:%2",position,line)
  IF position IS NULL OR position<0 THEN
    RETURN
  END IF
  LET at=position UNITS SECOND
  DISPLAY at TO at
END FUNCTION

FUNCTION displayPositionFromSlider(slider INT)
  IF m_duration IS NOT NULL AND m_duration > 0 THEN
    CALL DISPLAY_AT((slider*m_duration)/100)
  END IF
END FUNCTION

FUNCTION getMediaPosition(slider) --does only work in play mode
   DEFINE slider INT
   DEFINE position FLOAT
   LET position=fglcdvMedia.getCurrentPositionAudio(SOUNDID)
   IF position<0 THEN
     CALL displayPositionFromSlider(slider)
     RETURN slider
   END IF
   CALL DISPLAY_AT(position)
   LET slider=position*100/m_duration
   RETURN slider
END FUNCTION


--check if we got any timer data
FUNCTION checkFastTimer()
  DEFINE timerArr util.JSONArray
  DEFINE result STRING
  DEFINE volume FLOAT
  DEFINE volPercent INT
  IF m_FastTimer.getLength()==0 THEN
    RETURN
  END IF
  CALL ui.interface.frontcall("cordova","getAllCallbackData",[m_FastTimer],[result])
  LET timerArr=util.JSONArray.parse(result)
  IF timerArr.getLength() == 0 OR NOT m_IsRecording THEN
    RETURN
  END IF
  --GMI: the meters are only updated during actual recording
  --in paused state no metering is available 
  --possible enhancement in the plugin
  LET volume=fglcdvMedia.getCurrentAmplitudeAudio(SOUNDID)
  LET volPercent= (100*volume)
  DISPLAY volPercent TO meter
END FUNCTION

FUNCTION processCallback() 
  DEFINE mediaStatus util.JSONObject
  DEFINE mediaId,message STRING
  DEFINE messageType,code INT
  DEFINE d ui.Dialog
  CALL checkFastTimer()
  CALL fglcdvMedia.handleCallback()
  WHILE (mediaStatus:=getNextStatus()) IS NOT NULL
    LET messageType=fglcdvMedia.getMessageTypeFromStatus(mediaStatus)
    LET mediaId=fglcdvMedia.getMediaIdFromStatus(mediaStatus)
    DISPLAY "messageType:",fglcdvMedia.messageType2String(messageType),",mediaId:",mediaId
    CASE messageType
      WHEN fglcdvMedia.MEDIA_STATE
        LET m_state=fglcdvMedia.getStateFromStatus(mediaStatus)
        DISPLAY fglcdvMedia.mediaState2String(m_state) TO state
      WHEN fglcdvMedia.MEDIA_DURATION
        LET m_duration=fglcdvMedia.getDurationFromStatus(mediaStatus)
        DISPLAY "m_duration:",m_position
      WHEN fglcdvMedia.MEDIA_POSITION
        LET m_position=fglcdvMedia.getPositionFromStatus(mediaStatus)
        DISPLAY "m_position:",m_position
      WHEN fglcdvMedia.MEDIA_ERROR
        CALL fglcdvMedia.getErrorFromStatus(mediaStatus) RETURNING code,message
        IF m_IsRecording THEN
          LET m_IsRecording=FALSE
          CALL hideElement("record",FALSE)
          CALL hideElement("record_on",TRUE)
        END IF
        LET d=ui.Dialog.getCurrent()
        CALL setActionsOnStop(d)
        DISPLAY "message:",message,",code:",code
        CALL fgldialog.fgl_winMessage("Error",
               sfmt("%1%2code:%3",message,
               IIF(LENGTH(message)=0,"",","),
               code),
               "error")
    END CASE
  END WHILE
END FUNCTION

