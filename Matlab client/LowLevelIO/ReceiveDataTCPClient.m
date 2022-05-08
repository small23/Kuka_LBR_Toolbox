function res = ReceiveDataTCPClient(obj, count, type)
%RECEIVEDATATCPCLIENT Summary of this function goes here
%   Detailed explanation goes here
res = obj.lbr.read(count, type);
end