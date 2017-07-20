SELECT * 
 FROM sys.messages m where language_id = 1033 -- English
 --AND m.message_id =1480
AND ([message_id]=(9691) OR [message_id]=(35204) OR [message_id]=(9693) OR [message_id]=(26024) OR [message_id]=(28047) 
	OR [message_id]=(26023) OR [message_id]=(9692) OR [message_id]=(28034) OR [message_id]=(28036) OR [message_id]=(28048) 
	OR [message_id]=(28080) OR [message_id]=(28091) OR [message_id]=(26022) OR [message_id]=(9642) OR [message_id]=(35201) 
	OR [message_id]=(35202) OR [message_id]=(35206) OR [message_id]=(35207) OR [message_id]=(26069) OR [message_id]=(26070) 
	OR [message_id]>(41047) AND [message_id]<(41056) OR [message_id]=(41142) OR [message_id]=(41144) OR [message_id]=(1480) 
	OR [message_id]=(823) OR [message_id]=(824) OR [message_id]=(829) OR [message_id]=(35264) OR [message_id]=(35265))
ORDER BY Message_id