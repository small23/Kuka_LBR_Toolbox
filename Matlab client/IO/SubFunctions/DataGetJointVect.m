function [status, message, res] = DataGetJointVect(obj)
%DATAGETJOINTVECT Summary of this function goes here
%   Detailed explanation goes here
dataSize=IReceiveData(obj, 1, "int32");
data = IReceiveData(obj, dataSize, "double");
data=reshape(data,3,[])';
res=struct();
res.Zero=data(1,1:3);
res.JBase=data(2,1:3);
res.J1=data(3,1:3);
res.J2=data(4,1:3);
res.J3=data(5,1:3);
res.J4=data(6,1:3);
res.J5=data(7,1:3);
res.J6=data(8,1:3);
res.J7=data(9,1:3);
status=0;
message = "OK";
end

