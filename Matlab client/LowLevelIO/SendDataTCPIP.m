function SendDataTCPIP(obj,cmd)
%SENDDATATCPIP Summary of this function goes here
%   Detailed explanation goes here
fwrite(obj.lbr,cmd);
end