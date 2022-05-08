function [angles, status, msg] = GetInverseKinematics(obj, coords, orient, namevalue)
%GETINVERSEKINEMATICS Summary of this function goes here
%   Detailed explanation goes here

if ~isempty(namevalue.joints)
    if length(namevalue.joints)~=7
        ME = MException('iiwa:InvalidArgument', ...
            "Invalid argument 'joints'. Value must be a 1x7 vector!");
        throw(ME)
    end
    namevalue.useJointsPos=true;
end

if namevalue.useJointsPos
    if ~isempty(namevalue.e1) || ~isempty(namevalue.status) || ~isempty(namevalue.turn)
        ME = MException('iiwa:InvalidArgument', ...
            "You can`t specify both joint and redundancy information! Use E1+Status+Turn or Joint info only!");
        throw(ME)
    end
end

if (~isempty(namevalue.e1) || ~isempty(namevalue.status) || ~isempty(namevalue.turn))
    if ~(~isempty(namevalue.e1) && ~isempty(namevalue.status) && ~isempty(namevalue.turn))
        ME = MException('iiwa:InvalidArgument', ...
            "You must specifiy E1, Status and Turn!");
        throw(ME)
    end
end

if ~(size(coords,2)==3 && size(coords,1)==1) && ~(size(coords,2)==1 && size(coords,1)==3) 
    ME = MException('iiwa:InvalidArgument', ...
        "Invalid argument 'coords'. Value must be a 1x3 vector!");
    throw(ME)
end
if ~(size(orient,2)==3 && size(orient,1)==1) && ~(size(orient,2)==1 && size(orient,1)==3)
    ME = MException('iiwa:InvalidArgument', ...
        "Invalid argument 'orient'. Value must be a 1x3 vector!");
    throw(ME)
end

%---------------------

if (namevalue.toolRelated)
    transform = obj.getEefTransformationMatrix();
    res =  makehgtform('zrotate',orient(1))*...
        makehgtform('yrotate',orient(2))*makehgtform('xrotate',orient(3));
    flangeR = res(1:3,1:3)/transform(1:3,1:3);
    flangeT = coords-(flangeR*transform(1:3,4))';
    coords = flangeT;
    orient = rotm2eul(flangeR);
end

if namevalue.useLocalSolver==true
    Target = makehgtform('zrotate',orient(1))*...
        makehgtform('yrotate',orient(2))*makehgtform('xrotate',orient(3));
    Target (1:3,4) = coords/1000;
    
    if (namevalue.useJointsPos==true)
        if length(namevalue.joints)~=7
            namevalue.joints = obj.getJointAngels();
        end
        angles = GetInverseKinematicsLocalSolver(Target, eye(4), ...
            [0,0,0,0], [0,0,0], [0,0,0], ...
            nan, nan, rad2deg(namevalue.joints));
    else
        if ~isempty(namevalue.e1) && ~isempty(namevalue.status) && ~isempty(namevalue.turn)
            angles = GetInverseKinematicsLocalSolver(Target, eye(4), ...
                [0,0,0,0],  [0,0,0],  [0,0,0], ...
                rad2deg(namevalue.e1), namevalue.turn, 0);
        else
            angles = GetInverseKinematicsLocalSolver(Target, eye(4), ...
                [0,0,0,0],  [0,0,0],  [0,0,0], ...
                nan, nan, 0);
        end
    end
    
    if size(angles,1)>0
        angles = deg2rad(angles);
        msg = "OK";
        status = 0;
    else
        angles=[];
        status = 101;
        msg = "No solution!";
    end
else
    sendStr=uint8('<DKI');

    for j=1:3
        sendStr=[sendStr, flip(typecast(coords(j),"uint8"))];
    end
    for j=1:3
        sendStr=[sendStr, flip(typecast(orient(j),"uint8"))];
    end

    if (namevalue.useJointsPos==true)
        if ~isempty(namevalue.joints)
            sendStr=[sendStr, uint8(1)];
            for i=1:7
                sendStr=[sendStr, flip(typecast(namevalue.joints(i),"uint8"))];
            end
        else
            sendStr=[sendStr, uint8(2)];
        end
    else
        sendStr=[sendStr, uint8(0)];
    end
    if  ~isempty(namevalue.e1) && ~isempty(namevalue.status) && ~isempty(namevalue.turn)
        sendStr=[sendStr, uint8(1)];
        sendStr=[sendStr, flip(typecast(namevalue.e1,"uint8"))];
        sendStr=[sendStr, flip(typecast(int32(namevalue.status),"uint8"))];
        sendStr=[sendStr, flip(typecast(int32(namevalue.turn),"uint8"))];
    else
        sendStr=[sendStr, uint8(0)];
    end

    [angles, status, msg] = ReceiveResponse(obj, sendStr);
end
end