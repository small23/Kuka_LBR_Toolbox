classdef motion  < handle
    %MOTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        type string {mustBeMember(type,["ptp","spl", "lin", "relLin", "relSpl", "circ", "relCirc", "ptpJp"])}
        coords 
        orient
    end

    properties (SetAccess = private)
        E1 double = []
        vel double = []
        acc double = []
        status int32 = []
        blendingCart double = []
        blendingOri double = []
        blendingRel double = []
    end

    properties (Hidden)
        flags = int32(0)
    end
    
    methods
        function obj = motion(type, coords, orient)
            %PTP Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                type string {mustBeMember(type,["ptp","spl", "lin", "relLin", "relSpl", "circ", "relCirc","ptpJp"])}
                coords double
                orient double = []
            end
            if nargin<2
                ME = MException('motion:InvalidArgument', ...
                    "Not enouth arguments!");
                throw(ME)
            end

            if nargin==2 && type~="ptpJp"
                ME = MException('motion:InvalidArgument', ...
                    "Not enouth arguments!");
                throw(ME)
            end

            if type~="circ" && type~="relCirc" && type~="ptpJp"
                if ~(size(coords,2)==3 && size(coords,1)==1)
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'coords'. Value must be a 1x3 vector!");
                    throw(ME)
                end
                if ~(size(orient,2)==3 && size(orient,1)==1)
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'orient'. Value must be a 1x3 vector!");
                    throw(ME)
                end
            elseif type=="circ" || type=="relCirc"
                if ~(size(coords,2)==3 && size(coords,1)==2)
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'coords'. Value must be a 2x3 vector!");
                    throw(ME)
                end
                if ~(size(orient,2)==3 && size(orient,1)==2)
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'orient'. Value must be a 2x3 vector!");
                    throw(ME)
                end
            else
                 if ~(size(coords,2)==7 && size(coords,1)==1)
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'angels'. Value must be a 1x7 vector!");
                    throw(ME)
                end
            end

            obj.type=type;
            obj.coords=coords;
            if (type~="ptpJp")
                obj.orient=orient;
            end
        end

        function setE1(obj, angle, pointNumber)
            arguments
                obj
                angle
                pointNumber = 1
            end
            if (portNumber>1)
                if obj.type~="circ" && obj.type~="relCirc"
                    ME = MException('motion:InvalidArgument', ...
                        "Invalid argument 'pointNumber'. Value must be a 2x3 vector!");
                    throw(ME)
                end
            end
            obj.E1(pointNumber) = angle;
        end

         function setCartAccel(obj, acc)
            obj.acc=acc;
            obj.flags=bitset(obj.flags,1);
        end

        function resetCartAccel(obj)
            obj.flags=bitand(obj.flags,uint8(255-1));
            obj.acc = [];
        end

        function setCartVel(obj, vel)
            obj.vel=vel;
            obj.flags=bitset(obj.flags,2);
        end

        function resetCartVel(obj)
            obj.flags=bitand(obj.flags,uint8(255-2));
            obj.vel = [];
        end

        function setBlendingCart(obj)

        end

        function setBlendingOri(obj)

        end

        function setBlendingRel(obj)

        end

        function setBreakCondition(obj, type, param)
             arguments
                obj
                type string {mustBeMember(type,["force","point"])}
                param double = []
             end
        end
    end
end

