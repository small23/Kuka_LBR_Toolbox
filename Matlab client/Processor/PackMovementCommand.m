function sendStr = PackMovementCommand(motions, type)
%PACKMOVEMENTCOMMAND Summary of this function goes here
%   Detailed explanation goes here
if (type=="batch")
    sendStr=uint8(char("<MB"));
elseif (type=="spline")
    sendStr=uint8(char("<MS"));
elseif (type=="splineJp")
    sendStr=uint8(char("<MJ"));
else
    ME = MException('iiwa:InvalidArgument', ...
        sprintf("Invalid argument 'type'. Value must be a member of this set:\n    'batch'\n    'spline'\n    'splineJp'"));
    throw(ME)
end
sendStr = [sendStr, EncodeData(size(motions,2),"int32")];
for i=1:length(motions)
    switch motions{i}.type
        case "ptp"
            res = uint8(16); % b0001 0000 in dec
        case "lin"
            res = uint8(32); % b0010 0000 in dec
        case "spl"
            res = uint8(48); % b0011 0000 in dec
        case "circ"
            res = uint8(64); % b0100 0000 in dec
        case "relLin"
            res = uint8(128+32); % b1010 0000 in dec
        case "relSpl"
            res = uint8(128+48); % b1011 0000 in dec
        case "relCirc"
            res = uint8(128+64); % b1100 0000 in dec
        case "ptpJp"
            res = uint8(16); % b0001 0000 in dec
    end

    res=res+size(motions{i}.coords,2) * size(motions{i}.coords,1);
    res=res+size(motions{i}.orient,2) * size(motions{i}.orient,1);
    res=res+length(motions{i}.E1);
    sendStr=[sendStr,res];

    sendStr=[sendStr, EncodeData(motions{i}.flags, "int32")];
    if (motions{i}.type ~="circ" && motions{i}.type ~="relCirc")
        pointsCounter=1;
    else
        pointsCounter=2;
    end
    for ii=1:pointsCounter
        for j=1:size(motions{i}.coords,2)
            sendStr=[sendStr, EncodeData(motions{i}.coords(ii,j),"double")];
        end
        for j=1:size(motions{i}.orient,2)
            sendStr=[sendStr,  EncodeData(motions{i}.orient(ii,j),"double")];
        end
        if length(motions{i}.E1) >= ii
            if ~isnan(motions{i}.E1(pointsCounter))
                sendStr=[sendStr,  EncodeData(motions{i}.E1(ii,j),"double")];
            end
        end
    end
    if bitget(motions{i}.flags,1)
        sendStr=[sendStr, EncodeData(motions{i}.acc,"double")];
    end
    if bitget(motions{i}.flags,2)
        sendStr=[sendStr, EncodeData(motions{i}.vel,"double")];
    end
    if bitget(motions{i}.flags,3)

    end
end
end