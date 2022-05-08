function res= ReceiveDataTCPIP(obj, count, type)
%RECEIVEDATARCPIP Summary of this function goes here
%   Detailed explanation goes here
if (type ~= "char")
    res=zeros(1, count, type);
else
    res=char(zeros(1,count));
end
type = char(type);
if (count>0)
    res = fread(obj.lbr,count, type);
    res = cast(res,type)';
    if (size(res,1)>size(res,2))
        res=res';
    end
end
end