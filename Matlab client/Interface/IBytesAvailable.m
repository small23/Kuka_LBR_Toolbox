function res = IBytesAvailable(obj)
%IBYTESAVAILABLE Summary of this function goes here
%   Detailed explanation goes here
if obj.mode=="fast"
    res = BytesAvailTCPIP(obj);
elseif obj.mode=="safe"
    res = BytesAvailTCPClient(obj);
elseif obj.mode=="java"
    res = BytesAvailJava(obj);
end
end

