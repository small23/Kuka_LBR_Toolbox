function ISendData(obj,cmd)
%ISENDDATA Summary of this function goes here
%   Detailed explanation goes here
obj.lastCommand = cmd;
if obj.mode=="fast"
    SendDataTCPIP(obj,cmd);
elseif obj.mode=="safe"
    SendDataTCPClient(obj,cmd);
elseif obj.mode=="java"
    SendDataJava(obj,cmd);
end
end