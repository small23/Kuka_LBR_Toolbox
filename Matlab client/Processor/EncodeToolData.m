function res = EncodeToolData(toolname, tcp, mass, loadCentre)
%ENCODETOOLDATA Summary of this function goes here
%   Detailed explanation goes here
res = uint8('<CTN');
res= [res,EncodeData(toolname, "string")];
res = [res, EncodeData(mass,"double")];
for i=1:3
    res = [res, EncodeData(loadCentre(i),"double")];
end
for i=1:6
    res = [res, EncodeData(tcp(i),"double")];
end
end

