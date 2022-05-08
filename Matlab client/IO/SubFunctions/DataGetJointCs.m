function [status, message, res] = DataGetJointCs(obj)
%DATAGETJOINTCS Summary of this function goes here
%   Detailed explanation goes here
dataSize=IReceiveData(obj, 1, "int32");
data = IReceiveData(obj, dataSize, "double");
data = reshape(data,4,[])';
res=struct();
res.JBase=data(1:4,:);
res.J1=data(5:8,:);
res.J2=data(9:12,:);
res.J3=data(13:16,:);
res.J4=data(17:20,:);
res.J5=data(21:24,:);
res.J6=data(25:28,:);
res.J7=data(29:32,:);
res.Flange=data(33:36,:);
status=0;
message = "OK";
end

