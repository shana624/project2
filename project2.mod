MODULE Mainmodule 
	CONST robtarget pHOME:=[[345.45,-11.35,431.63],[0.000140797,0.445293,-0.895385,-3.19097E-05],[-1,-1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget con_end:=[[610.45,-10.65,136.93],[3.69486E-05,0.0432263,0.999065,5.76757E-05],[-1,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget wHOME:=[[352.37,-286.74,431.52],[0.000230266,0.445463,-0.8953,-2.08847E-05],[-1,-1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget bHOME:=[[358.23,271.62,431.51],[0.00023888,0.445484,-0.89529,-5.91875E-05],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_blf:=[[425.54,230.27,156.13],[0.0960839,-0.0961422,0.700565,0.700524],[0,1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_brf:=[[427.14,325.23,160.87],[0.422463,0.422477,-0.567033,0.56702],[0,-1,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_blb:=[[306.08,230.73,156.13],[0.0960883,-0.0961351,0.700557,0.700532],[0,1,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_brb:=[[307.24,324.11,160.88],[0.422497,0.422474,-0.567008,0.567022],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_wlf:=[[411.44,-327.91,137.38],[0.0961103,-0.0961523,0.700552,0.700532],[-1,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_wrf:=[[413.77,-232.96,138.79],[0.422464,0.422483,-0.567051,0.566996],[-1,-2,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_wlb:=[[300.55,-329.87,137.39],[0.0960974,-0.0961348,0.700528,0.70056],[-1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget p_wrb:=[[300.23,-235.00,137.24],[0.42247,0.422485,-0.56708,0.566962],[-1,-2,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
	VAR socketdev server_socket;	!???? ?? ????
	VAR socketdev client_socket;	!????? ?? ????
	VAR string received_string;		!?? ?? ?? ????
	VAR bool keep_listening := TRUE;	!???? ??
	VAR socketstatus status_soc;		!?? ?? ?? ??
	VAR string client_ip;			!????? ip?? ??
	VAR num len;					!??? ?? ?? ??
    
    VAR intnum interrupt_sign;
     
    PROC main()
        CONNECT interrupt_sign WITH E_STOP;
		ISignalDI di09_interrupt, high, interrupt_sign;
		IWatch interrupt_sign;
        
        AccSet 1,1;
		
		SocketCreate server_socket;		!?? ?? ??
		SocketBind server_socket, "10.10.32.143", 5000;	!?? ip ???? ???
		SocketListen server_socket;		!??? ?? ??
		SocketAccept server_socket, client_socket\ClientAddress:=client_ip;	!??????? ?? ?? ??

		WHILE keep_listening DO	!??? ???? ??
    		! Waiting for a connection request
	   		status_soc := SocketGetStatus(server_socket);	!?? ?? ?? ??
    		TPWrite "status_soc - " \num := status_soc;		
    		TPWrite client_ip;								!????? ip??
    		
    		IF(status_soc = SOCKET_CLOSED)THEN				!??? ?? ????, ????? ??
    			SocketAccept server_socket, client_socket;
    		ENDIF

    		! Communication
    		SocketReceive client_socket \Str:=received_string;	!?? ??? ??
    		TPWrite "Client wrote - " + received_string;
			
			len := StrLen(received_string);						!?? ??? ????
			
			received_string := StrPart(received_string,1,5);	!?? ??? 1~3??? ??
			
			IF received_string="start" THEN
                PulseDO\PLength:=0.2,do18_flag_clear;
                TPErase;
                TPWrite "Process Start";
                SocketSend client_socket \Str:="proc start";
                
                WHILE di18_end_proc = 0 DO
                    
				    IF di02_mag_none = 0 AND di07_running = 0 THEN
                        MoveJ pHOME, v200, z30, tool_csh;
                        PulseDO\PLength:=0.2,do02_plcstart;
                    ENDIF
                    
                    IF di06_arrive = 1 THEN
                        
                        con_end_proc;
                        MoveJ pHOME, v200, fine, tool_csh;
                        TPWrite "Pick up End";
                        SocketSend client_socket \Str:="Pick up End";
        				
                        IF di04_plastic_black = 1 THEN
        					PulseDO\PLength:=0.2,do03_reset_jedg;
                            MoveJ bHOME, v200, z30, tool_csh;
                            b_proc;
        				ELSEIF di05_plastic_white = 1 THEN
        					PulseDO\PLength:=0.2,do03_reset_jedg;
                            MoveJ wHOME, v200, z30, tool_csh;
                            w_proc;
				        ENDIF
                        
                    ENDIF      
                    
                ENDWHILE
                SocketSend client_socket \Str:="proc end";
                TPWrite "Process End";
                
			ENDIF
           
		
		ENDWHILE
		
		ERROR
		IF ERRNO=ERR_SOCK_TIMEOUT THEN
			TPWrite "SOCK Time out Retry";
			RETRY;
		ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
			RETURN;
		ELSE
			! No error recovery handling
		ENDIF
		
	ENDPROC      
     
    PROC con_end_proc()
		MoveJ Offs(con_end,0,0,60), v200, z30, tool_csh;
		MoveL con_end, v30, fine, tool_csh;
		grip_on;
		MoveL Offs(con_end,0,0,60), v100, z30, tool_csh;
	ENDPROC	
    
    PROC grip_on()
		PulseDO\PLength:=0.2,do00_grip_on;			
		WaitDI di00_grip_on_sen,1;
	ENDPROC

	PROC grip_off()
		PulseDO\PLength:=0.2,do01_grip_off;
		WaitDI di01_grip_off_sen,1;
	ENDPROC
    
    PROC b_proc()
		IF di10_blf_on = 0 THEN
            blf;
        ELSEIF di11_brf_on = 0 THEN
            brf;
        ELSEIF di12_blb_on = 0 THEN
            blb;
        ELSEIF di13_brb_on = 0 THEN
            brb;
        ENDIF
	ENDPROC
    
    PROC w_proc()
		IF di14_wlf_on = 0 THEN
            wlf;
        ELSEIF di15_wrf_on = 0 THEN
            wrf;
        ELSEIF di16_wlb_on = 0 THEN
            wlb;
        ELSEIF di17_wrb_on = 0 THEN
            wrb;
        ENDIF
    ENDPROC
    
    PROC blf()	
        MoveJ Offs(p_blf,0,-80,0), v200, fine, tool_csh;
        MoveJ p_blf, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_blf,0,-80,0), v200, fine, tool_csh;
        TPWrite "blf done";
        SocketSend client_socket \Str:="blf done";	
        MoveJ bHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do10_blf;
    ENDPROC
    
    PROC brf()
        MoveJ Offs(p_brf,0,80,0), v200, fine, tool_csh;
        MoveJ p_brf, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_brf,0,80,0), v200, fine, tool_csh;
        TPWrite "brf done"; 
        SocketSend client_socket \Str:="brf done";
        MoveJ bHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do11_brf;
    ENDPROC
    
    PROC blb()
        MoveJ Offs(p_blb,0,-80,0), v200, fine, tool_csh;
        MoveJ p_blb, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_blb,0,-80,0), v200, fine, tool_csh;
		TPWrite "blb done";
        SocketSend client_socket \Str:="blb done";	
        MoveJ bHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do12_blb;
    ENDPROC
    
    PROC brb()
        MoveJ Offs(p_brb,0,80,0), v200, fine, tool_csh;
        MoveJ p_brb, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_brb,0,80,0), v200, fine, tool_csh;
        TPWrite "brb done";
        SocketSend client_socket \Str:="brb done";	
        MoveJ bHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do13_brb;
    ENDPROC
    
    PROC wlf()
        MoveJ Offs(p_wlf,0,-80,0), v200, fine, tool_csh;
        MoveJ p_wlf, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_wlf,0,-80,0), v200, fine, tool_csh;
        TPWrite "wlf done";
        SocketSend client_socket \Str:="wlf done";	
        MoveJ wHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do14_wlf;
    ENDPROC
    
    PROC wrf()
        MoveJ Offs(p_wrf,0,80,0), v200, fine, tool_csh;
        MoveJ p_wrf, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_wrf,0,80,0), v200, fine, tool_csh;
        TPWrite "wrf done";
        SocketSend client_socket \Str:="wrf done";	
        MoveJ wHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do15_wrf;
    ENDPROC
        
    PROC wlb()
        MoveJ Offs(p_wlb,0,-80,0), v200, fine, tool_csh;
        MoveJ p_wlb, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_wlb,0,-80,0), v200, fine, tool_csh; 
        TPWrite "wlb done";
        SocketSend client_socket \Str:="wlb done";	
        MoveJ wHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do16_wlb;
    ENDPROC
    
    PROC wrb()
        MoveJ Offs(p_wrb,0,80,0), v200, fine, tool_csh;
        MoveJ p_wrb, v30, fine, tool_csh;
        grip_off;
        MoveJ Offs(p_wrb,0,80,0), v200, fine, tool_csh;
        TPWrite "wrb done";
        SocketSend client_socket \Str:="wrb done";
        MoveJ wHOME, v200, z30, tool_csh;
        MoveJ pHOME, v200, z30, tool_csh;
        PulseDO\PLength:=0.2,do17_wrb;
    ENDPROC
    
    TRAP E_STOP
		VAR robtarget e_stop_pos;
		StopMove;
		StorePath;
		SocketSend client_socket \Str:="emergency";
        TPWrite "Emergency stop";
		WaitDi di09_interrupt,0;
        SocketSend client_socket \Str:="proc start";
        TPWrite "Process restart";
		RestoPath;
		StartMove;
	ENDTRAP
    
ENDMODULE
     
