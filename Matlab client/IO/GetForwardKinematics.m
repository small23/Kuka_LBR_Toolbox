function [data, status, msg] = GetForwardKinematics(obj, angles,nameval)
%GETFORWARDKINEMATICS Summary of this function goes here
%   Detailed explanation goes here

if ~(size(angles,2)==7 && size(angles,1)==1)
    ME = MException('iiwa:InvalidArgument', ...
        "Invalid argument 'angles'. Value must be a 1x7 vector!");
    throw(ME)
end

if (nameval.useLocalSolver == true)
    status = 0;
    msg = 'OK';
    data = GetForwardKinematicsLocalSolver(angles);
    if (nameval.toolRelated)
        transform = obj.getEefTransformationMatrix();
        data.Tool = data.Flange * transform;
    end
else
    sendStr=uint8('<DKF');
    for j=1:7
        sendStr=[sendStr, flip(typecast(angles(j),"uint8"))];
    end

    [data, status, msg] = ReceiveResponse(obj, sendStr);
    if (status==1)
        if (nameval.toolRelated)
            transform = obj.getEefTransformationMatrix();
            data.Tool = data.Flange * transform;
        end
    end
end
end

