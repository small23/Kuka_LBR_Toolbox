function res = EncodeData(data, type)
%ENCODEDATA Summary of this function goes here
%   Detailed explanation goes here
arguments
    data
    type string {mustBeMember(type,["string","double", "int32", "uint8", "char"])}
end

res=uint8([]);

if (type=="string")
    res = flip(typecast(int32(strlength(data)), 'uint8'));
    res = [res, uint8(char(data))];
else
    data = cast(data,type);
    res = [res, flip(typecast(data, "uint8"))];
end
end

