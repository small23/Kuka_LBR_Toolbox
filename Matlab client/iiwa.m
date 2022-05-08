classdef iiwa < handle
    %IIWA Communication classs for Kuka LBR iiwa
    %   Provides information and control methods for LBR iiwa

    %% ---------------Constructor--------------
    methods
        function obj = iiwa(params)
            %IIWA Construct an instance of this class
            %   Detailed explanation goes here
            % Параметры:
            % ip - Строка с адресом контроллера. Адрес можно посмотреть в
            % Station -> Information -> IP
            %
            % port - Число, обозначающее порт, через который будет идти
            % подключение. Диапазон от 30000 до 30010. Номер порта задатеся
            % в конфигурации сервера.
            %
            % mode - Режим соединения с роботом:
            %   "safe" - Используется внутренний класс tcpclient.Наиболее
            %   современный способ коммуникации в MATLAB, однако самый
            %   медленный (150 пакетов в секунду).
            %   "fast" - Используется устаревший класс TCPIP. Поддержка
            %   прекращена с выпуска r2020b. Не смотря на это может быть
            %   быстрее safe режима (~1400 пакетов в секунду).
            %   "java" - Используется самопальная обертка над java-сокетом.
            %   Может содержать некоторые баги, но режим на 1 порядок
            %   быстрее "fast"-режима (~15000 пакетов в секунду)

            arguments
                params.ip string = "172.31.1.147"
                params.port double {mustBeInRange(params.port, 30000, 30010)} = 30001
                params.mode string {mustBeMember(params.mode, ["safe", "fast", "java", "offline"])} = "java"
                params.throwExceptionOnError logical = false
            end
            obj.init(params);
        end
    end

    %% ------------Public properties-----------
    properties (GetAccess=public, SetAccess=private)
        ios = []% Содержит описание всех IO-портов в роботе
        throwExceptionOnError logical = false
    end

    %% ---Data and information getter methods--
    methods
        function [name, status, msg] = getControllerName(obj)
            %GETCONTROLLERNAME Getting current angels of joints
            %   Метод отдает имя контроллера, на котором запущен сервер.
            %
            %   Arguments:
            %   None
            %
            %   Output:
            %   name - string that contains name of used Kuka Sunrise controller
            %   status - command status value. 1 means successful command
            % execution. A value other than 1 - the command was executed
            % with an error.
            %   msg - additional message. Perhaps this field will tell you 
            % the reason for the error
            [name, status, msg]  = ReceiveResponse(obj, "<INC");
        end

        function [coords, orient, e1, status, turn, statConn, msg] = getEefCoordinates(obj)
            %GETEEFCOORDINATES 
            %   Метод отдает координаты EEF (в зависимости от
            %   установленного инструмента это или координаты инструмента,
            %   или координаты фланца)
            %   Arguments:
            %   None
            %
            %   Output:
            %   coords - массив 1*3 с координатами EEF, в мм
            %   orient - Углы Эйлера EEF, в радианах
            %   e1 - Угол избыточности, в радианах
            %   status - Статус позы
            %   turn - Turn параметр позы
            %   statConn - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.

            [feedback, statConn, msg] =ReceiveResponse(obj, "<DPE");
            if (statConn==0)
                coords=feedback.coords(1:3);
                orient = feedback.coords(4:6);
                e1 = feedback.e1;
                status = feedback.statusF;
                turn = feedback.turn;
            else
                coords=[];
                orient = [];
                e1 = [];
                status = [];
                turn = [];
            end
        end

        function [angles, status, msg] = getEefTransformationAngle(obj)
            %GETEEFTRANSFORMATIONANGLE Summary of this method goes here
            %   Метод отдает углы поворота EEF относительно фланца.
            %   Arguments:
            %   None
            %
            %   Output:
            %   angles - Углы Эйлера поворота EEF относительно фланца, в
            %   радианах
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [angles, status, msg] = ReceiveResponse(obj, "<ITA");
        end

        function [matrix, status, msg] = getEefTransformationMatrix(obj)
            %GETEEFTRANSFORMATIONMATRIX Summary of this method goes here
            %   Метод отдает матрицу перехода EEF относительно фланца.
            %   Arguments:
            %   None
            %
            %   Output:
            %   matrix - Матрица перехода EEF, расстояния в мм
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [eefAngles, status1, msg1] = ReceiveResponse(obj, "<ITA");
            [eefVector, status2, msg2] = ReceiveResponse(obj, "<ITV");
            if status1 == 0 && status2 == 0
                matrix = makehgtform('zrotate',eefAngles(1))*...
                    makehgtform('yrotate',eefAngles(2))*makehgtform('xrotate',eefAngles(3));
                matrix(1:3,4) = eefVector';
                status=1;
                msg=msg1;
            else
                matrix=[];
                if status1~=0
                    status=status1;
                    msg=msg1;
                else
                    status=status2;
                    msg=msg2;
                end
            end
        end

        function [vector, status, msg] = getEefTransformationVector(obj)
            %GETEEFTRANSFORMATIONVECTOR Summary of this method goes here
            %   Метод отдает смещение EEF относительно фланца.
            %   Arguments:
            %   None
            %
            %   Output:
            %   vector - Смещение EEF относительно фланца, в мм
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [vector, status, msg] = ReceiveResponse(obj,"<ITV");
        end

        function [force, status, msg] = getForceOnEef(obj)
            %   Метод отдает усилия, оказываемые на  EEF по осям XYZ. В
            %   случае если инструмент не установлен, метод отдает усилия
            %   на фланце.
            %   Arguments:
            %   None
            %
            %   Output:
            %   force - Усилия на EEF
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [force, status, msg] = ReceiveResponse(obj, "<DPFT");
        end

        function [force, status, msg] = getForceOnFlange(obj)
            %   Метод отдает усилия на фланце робота, независимо от 
            %   установленного инструмента.
            %   Arguments:
            %   None
            %
            %   Output:
            %   force - Усилия на фланце
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [force, status, msg] = ReceiveResponse(obj, "<DPFF");
        end

        function [data, status, msg] = getForwardKinematics(obj, angles, nameval)
            %GETFORWARDKINEMATICS Summary of this method goes here
            %   Метод рассчитывает положение робота относительно данных
            %   углов.
            %
            %   Arguments:
            %   angles - Углы поворота осей с 1 по 7, массив 1*7. Углы в радианах.
            %   toolRelated - Флаг указывающий, что координаты необходимо
            %   рассчитать для установленного инструмента. Если значение
            %   установленно true - алгоритм отдаст данные EEF. Иначе будут
            %   даны данные для фланца.
            %
            %   Output:
            %   data - Структура, содержащая матрицу перехода для каждой из
            %   осей.
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            %
            %   Примеры:
            %   lbr = iiwa();
            %   angles = [0,0,0,0.5,0,0,0];
            % %Получаем данные для фланца
            %   data = lbr.getForwardKinematics(angles);
            %   lbr.attachTool("Nase");
            % %Получаем данные для установленного инструмента.
            %   data2 = lbr.getForwardKinematics(angles, "toolRelated", true);
            arguments
                obj iiwa
                angles double
                nameval.toolRelated logical = true; %The flag indicates
                nameval.useLocalSolver logical = false; %
                % that these are the coordinates of the tool, not the flange
            end
            [data, status, msg] = GetForwardKinematics(obj, angles,nameval);
        end

        function [angles, status, msg] = getInverseKinematics(obj, coords, orient, nameval) %Из координат конфигурацию
            %GETINVERSEKINEMATICS Summary of this method goes here
            %   Метод рассчитывает конфигурацию робота относительно
            %   введенных данных. Рассчет может вестись относительно:
            %   1) Текущей конфигурации робота ("useJointsPos", true)
            %   2) Указанной конфигурации робота ("joints", [0,0,0,0,0,0,0])
            %   3) Данным избыточности (Параметры e1, status, turn. Должны
            %   быть указаны ВСЕ параметры)
            %   4) Только относительно координат и ориентации EEF.
            %
            %   Arguments:
            %   coords - массив 1*3 с координатами EEF, в мм
            %   orient - Углы Эйлера EEF, в радианах
            %   
            %   Опциональные параметры:
            %   e1 - Угол избыточности, в радианах
            %   status - Статус позы
            %   turn - Turn параметр позы
            %   useJointsPos - Флаг, указывающий что для рассчета
            %   необходимо учитывать текущую конфигурацию робота.
            %   joints - Углы поворота осей с 1 по 7, массив 1*7. Углы в радианах.
            %
            %   useLocalSolver - Флаг, указывающий, что для рассчета
            %   необходимо использовать локальный солвер конфигурации.
            %   Может быть полезно, если солвер Ивы не может рассчитать
            %   конфигурацию. По умолчанию используется солвер Ивы.
            %   toolRelated - Флаг указывающий, что координаты необходимо
            %   рассчитать для установленного инструмента. Если значение
            %   установленно true - алгоритм отдаст данные EEF. Иначе будут
            %   даны данные для фланца. По умолчанию True
            %
            %   Output:
            %   data - Структура, содержащая матрицу перехода для каждой из
            %   осей.
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            %
            %   Примеры:
            %   t = iiwa();
            % %Получаем конфигурацию относительно инструмента, с
            % использованием текущей конфигурации робота
            %   t.getInverseKinematics([500,0,600],deg2rad([0,90,0]),"toolRelated",true,"useJointsPos",true);
            % %Получаем конфигурацию относительно инструмента, с учетом указанной позы 
            %   t.getInverseKinematics([500,0,600],deg2rad([0,90,0]),"toolRelated",true,"joints",[0,0,0,0,0,0,0]);
            % %Получаем конфигурацию при указанных параметрах избыточности
            % относительно фланца робота
            %   t.getInverseKinematics([500,0,600],deg2rad([0,90,0]),"toolRelated",false,"e1",0,"status",2,"turn",22);
            arguments
                obj iiwa
                coords double
                orient double
                nameval.joints double = []
                nameval.useJointsPos logical = false
                nameval.e1 = [];
                nameval.status = [];
                nameval.turn = [];
                nameval.toolRelated logical = true; 
                nameval.useLocalSolver logical = false;
            end
            [angles, status, msg] = GetInverseKinematics(obj, coords, orient, nameval);
        end

        function [angles, status, msg] = getJointAngels(obj)
            %GETJOINTANGELS Getting current angels of joints
            %   Метод отдает углы поворота каждой оси робота в текущей
            %   конфигурации
            %   Arguments:
            %   None
            %
            %   Output:
            %   angles - углы поворота осей робота с 1 по 7, в радианах
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.

            [angles, status, msg] = ReceiveResponse(obj, "<DPA");
        end

        function [cs, status, msg] = getJointCoordinateSystem(obj)
            %GETJOINTANGELS Summary of this method goes here
            %   Метод отдает матрицы перехожа осей робота для текущей
            %   конфигурации до фланца
            %   Arguments:
            %   None
            %
            %   Output:
            %   cs - Матрицы перехода для каждой оси
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.

            [cs, status, msg] = ReceiveResponse(obj, "<DPJC");
        end

        function [vectors, status, msg] = getJointVectors(obj)
            %GETJOINTANGELS Summary of this method goes here
            %   Detailed explanation goes here

            [vectors, status, msg] = ReceiveResponse(obj, "<DPJV");
        end

        function [points, status, msg] = getPoints(obj)
            %GETPOINTS Summary of this method goes here
            %   Метод отдает список сохраненных в памяти робота точки.
            %   Arguments:
            %   None
            %
            %   Output:
            %   points - Массив структур, хранящий данные по каждой точке.
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.

            [points, status, msg] = ReceiveResponse(obj, "<IP");
        end

        function [name, status, msg] = getRobotName(obj)
            %GETROBOTNAME Getting current angels of joints
            %   Detailed explanation goes here

            [name, status, msg] = ReceiveResponse(obj, "<INR");
        end

    end

    %% ----------Connections methods----------
    methods
        function [time, status, msg] = ping(obj)
            %PING Checking connection and requered time to communicate with LBR iiwa
            %   Detailed explanation goes here

            [time , status, msg] = PingConn(obj);
        end

        function [status, msg] = checkConnection(obj)
            [~,status, msg] = ReceiveResponse(obj, "<CCC");
        end
    end

    %% ------Object manipulation methods------
    methods
        function [names, status, msg] = toolToolsAvailable(obj)
            %   Метод отдает список доступных для установки инструментов.
            %   Arguments:
            %   None
            %
            %   Output:
            %   names - Массив строк с названиями инструментов
            %   status - Результат запроса. 1 означает успешное
            %   выполнение, число отличное от 1 - ошибку выполнения.
            %   msg - Дополнительное сообщение. Может быть полезно для
            %   получания информации об ошибке.
            [names, status, msg] = ReceiveResponse(obj, "<INT");
        end
        
        function [status, msg] = toolDeattach(obj)
            % Отсоеденить интрумент
            [~, status, msg] = ReceiveResponse(obj, "<CTD");
        end

        function [status, msg] = toolAttach(obj, toolname) %TODO to add LoadData
            % Установить инструмент по имени. Использует базу имеющихся
            % инструментов с робота. Имена инструментов можно получить с
            % помощью команды toolToolsAvailable
            msg = uint8(char("<CTA"));
            msg = [msg, EncodeData(toolname, "string")];
            [~, status, msg] = ReceiveResponse(obj, msg);
        end

        function [name, status, msg] = toolCurrent(obj)
            % Текущий инструмент
            [name, status, msg] = ReceiveResponse(obj, "<CTC");
        end
        
        function [frames, status, msg] = toolGetFrames(obj, toolname, transformCoordinates)
            arguments
                obj iiwa
                toolname string = ""
                transformCoordinates logical = true % Привести смещение фрейма к фланцу
                % Если стоит false то даются данные трансформации фрейма
                % относительно его родителя (в пути фрейма предыдудщий фрейм)
            end
            msg = uint8(char("<CTF"));
            msg = [msg, EncodeData(toolname, "string")];
            [frames, status, msg] = ReceiveResponse(obj, msg, true);
            if (transformCoordinates)
                frames = TransformFramesToFlange(frames);
            end
        end

        function [status, msg] = toolSetFrameByName(obj, frameName)
            % Изменить фрейм инструмента на другой с помощью имени. Имена
            % доступных фреймов можно получить с помощью метода toolGetFrames
            msg = uint8(char("<CTS"));
            msg = [msg, EncodeData(frameName, "string")];
            [~, status, msg] = ReceiveResponse(obj, msg);
        end

        function [status, msg] = toolAttachNew(obj, toolname, tcp, mass, loadCentre)
            % Устанавливает новый инструмент с указанными параметрами
            % перехода и веса. Может иметь только 1 фрейм.
            msg = EncodeToolData(toolname, tcp, mass, loadCentre);
            [~, status, msg] = ReceiveResponse(obj, msg);
        end

        function [status, msg] = ioSetOutput(obj, group, name, value)
            allCN = [obj.ios.group];
            tf1 = allCN == group;
            index = find(tf1);
            temp = obj.ios(index);
            allCN = [temp.name];
            tf1 = allCN == name;
            index = tf1;
            temp = temp(index);
            allCN = [temp.typeIO];
            tf1 = allCN == "Output";
            index = find(tf1);
            output = temp(index);
            if length(output)==1
                
            end
        end

        function [value, status, msg] = ioReadIO(obj, group, name)
            
        end

    end

    %% -------------Motion methods------------
    methods
        function [status, msg] = ptp(obj, coords, orient)
            %PTP PTP move
            %   Moves iiwa to the specified coordinates, PTP movement. This
            %   is synchronous method. If there are more than 1 point -
            %   points will be grouped in batch move.
            %
            %   Arguments:
            %   coords - 2-d array N by 3, x, y, z coords. N - number of
            %   movements
            %   orient - 2-d array N by 3 A, B, C angle of move
            %
            %   Output:
            %   feedback - reserved

            commands = ConvertCommands("ptp", [coords orient]);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "batch");
        end

        function [status, msg] = lin(obj, coords, orient)
            %LIN LIN move
            %   Moves iiwa to the specified coordinates, LIN movement. This
            %   is synchronous method. If there are more than 1 point -
            %   points will be grouped in batch move
            %
            %   Arguments:
            %   coords - 2-d array N by 3, x, y, z coords. N - number of
            %   movements
            %   orient - 2-d array N by 3 A, B, C angle of move
            %
            %   Output:
            %   feedback - reserved

            commands = ConvertCommands("lin", [coords orient]);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "batch");
        end

        function [status, msg] = spl(obj, coords, orient)
            %SPL SPL move
            %   Moves iiwa to the specified coordinates, SPL movement. This
            %   is synchronous method
            %
            %   Arguments:
            %   coords - 2-d array N by 3, x, y, z coords. N - number of
            %   movements
            %   orient - 2-d array N by 3 A, B, C angle of move
            %
            %   Output:
            %   feedback - reserved

            commands = ConvertCommands("spl", [coords orient]);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "batch");
        end

        function [status, msg] = relLin(obj, coords, orient)
            %RELLIN Relative LIN move
            %   Shifts iiwa relative to the current coordinates, LIN
            %   movement. This is synchronous method. If there are more
            %   than 1 point - points will be grouped in batch move
            %
            %   Arguments:
            %   coords - 2-d array N by 3, x, y, z coords. N - number of
            %   movements
            %   orient - 2-d array N by 3 A, B, C angle of move
            %
            %   Output:
            %   feedback - reserved

            commands = ConvertCommands("relLin", [coords orient]);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "batch");
        end

        function [status, msg] = relSpl(obj, coords, orient)
            %RELSPL Relative SPL move
            %   Shifts iiwa relative to the current coordinates, SPL
            %   movement. This is synchronous method. If there are more
            %   than 1 point - points will be grouped in batch move
            %
            %   Arguments:
            %   coords - 2-d array N by 3, x, y, z coords. N - number of
            %   movements
            %   orient - 2-d array N by 3 A, B, C angle of move
            %
            %   Output:
            %   feedback - reserved

            commands = ConvertCommands("relSpl", [coords orient]);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "spline");
        end

        function [status, msg] = splineJP(obj, angels)
            commands = ConvertCommands("ptpJp", angels);
            [status, msg] = AbstractSyncMoveCommand(obj, commands, "splineJp");
        end

        function [status, msg] = complexMove(obj, batchType, points)
            %MOVEMIXED Complex move
            %   Moves iiwa to the specified coordinates and with specified
            %   mode. This is synchronous method
            %
            %   Arguments:
            %   batchType - Batch type: "spline" or simple "batch"
            %   points - Cell array with motion class, 1xN dim
            %
            %   Output:
            %   feedback - reserved

            arguments
                obj iiwa
                batchType string {mustBeMember(batchType,["batch","spline","splineJp"])}
                points cell
            end

            [status, msg] = AbstractSyncMoveCommand(obj, points, batchType);
        end

    end

    %%---------------Utils--------------------
    methods
        function axisAngles = decodeTurnStatus(~, turn)
            axisAngles = bitget(turn,1:1:7);
        end

        function angles = getAngelsFromTransMatix(~, T)
            angles = rotm2eul(T(1:3,1:3));
        end

        function drawPosition(obj, plt, data, nameval)
             arguments
                obj iiwa
                plt
                data
                nameval.data string {mustBeMember(nameval.data, ["angles", "transMatrix", "coords"])}
                nameval.symbol string {mustBeMember(nameval.symbol, ["+", "o"])} = 'o'
                nameval.drawRobotPose logical = false
             end
             DrawPosition(obj, plt, data, nameval);
        end
    end

    %% ---------------------------------------
    %% -----------End of public zone----------
    %% ---------------------------------------
    %% -------Local properties of class-------
    properties (Hidden)
        lbr = []         % Contains connection object
        mode = []        % Contains network connection type (via tcpclient, tcpip or java socket)
        lbrAns = []      % Help structure
        ip = []          % Connection address
        port = []        % Connection port
        lastCommand = [] % Last sended byte array
    end

    methods (Hidden)
        function flush(obj)
            %FLUSH Summary of this function goes here
            %   Detailed explanation goes here

            if obj.mode=="fast"
                flushinput(obj.lbr);
                flushoutput(obj.lbr);
            elseif obj.mode=="safe"
                flush(obj.lbr);
            elseif obj.mode=="java"
                obj.lbr.out.flush();
                IReceiveData(obj, IBytesAvailable(obj), "uint8");
            end
        end
        %In development
    end

    %% -------------Debug methods-------------
    methods (Hidden)
        function res = getLastCommand(obj)
            res = obj.lastCommand;
        end

        function res = getDebugCoords(obj)
            res=ReceiveResponse(obj, "<DPD");
        end
    end

    %% -------------Internal group------------
    methods (Access = private)
        function init(obj, params)
            %INIT Summary of this function goes here
            %   Detailed explanation goes here

            folder = fileparts(which('iiwa.m'));
            addpath(genpath(folder));

            obj.lbrAns = SetPossibleAns();
            obj.port = params.port;
            obj.mode = params.mode;
            
            if (obj.mode == "offline")
                obj.ios = [];
                obj.lbr = [];
                warning("LBR iiwa class is initialized in offline mode! " + ...
                        "Most of the library features are not available for execution. " + ...
                        "Use offline mode only for debugging your application or writing code!")
                return
            end

            % Checking field
            if (regexp(params.ip, "^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$") || params.ip=="localhost") %MAGIC
                obj.ip = params.ip;
            else
                ME = MException('iiwa:InvalidArgument', ...
                    'Variable IP is not valid ip!');
                throw(ME)
            end

            bufferSize=65536;
            timeout = 5.0;
            % Creating connection
            try
                if obj.mode=="safe" % Using std tcpclient , new class, safeer, than old tcpip
                    obj.lbr = tcpclient(obj.ip, obj.port, "ConnectTimeout", 5);
                    obj.lbr.ByteOrder="big-endian";
                    obj.lbr.Terminator('','');
                    obj.lbr.Timeout=timeout;
                elseif obj.mode=="fast" % faster communication way, up to 400 packages\sec
                    obj.lbr = tcpip(obj.ip, obj.port, 'NetworkRole', 'Client', 'Terminator',['','']); %#ok<TCPC>
                    obj.lbr.TransferDelay='off';
                    obj.lbr.OutputBufferSize=bufferSize;
                    obj.lbr.InputBufferSize=bufferSize;
                    obj.lbr.Timeout=timeout;
                    fopen(obj.lbr);
                    warning("TCPIP is depricated in Matlab 2020b and higher! " + ...
                        "If you need fast communication, it`s recommended " + ...
                        "to use 'java' communication mode.")
                elseif obj.mode=="java" % Communication via java sockets
                    obj.lbr.client = javaObject('java.net.Socket', obj.ip, int32(obj.port));
                    obj.lbr.client.setTcpNoDelay(false);
                    obj.lbr.client.setSoTimeout(int32(timeout*1000));
                    obj.lbr.timeout=timeout;
                    obj.lbr.client.setReceiveBufferSize(bufferSize);
                    obj.lbr.client.setSendBufferSize(bufferSize);
                    obj.lbr.out = obj.lbr.client.getOutputStream();
                    obj.lbr.in = obj.lbr.client.getInputStream();
                    obj.lbr.wrapper = JavaMethodWrapper(obj.lbr.in, 'read(byte[],int,int)');
                end
            catch
                ME = MException('iiwa:IOExeption', ...
                    'Unable to connect to %s:%d via %s mode!', obj.ip, obj.port, obj.mode);
                throw(ME)
            end
            res = ReceiveResponse(obj,  "<II");
            obj.ios = res;
        end

        function closeCon(obj)
            %CLOSECON Summary of this function goes here
            %   Detailed explanation goes here

            try
                if ~isempty(obj.lbr)
                    if obj.mode=="fast"
                        fclose(obj.lbr);
                    elseif (obj.mode=="java")
                        if (obj.lbr.client.isConnected)
                            obj.lbr.in.close();
                            obj.lbr.out.close();
                            obj.lbr.client.close();
                        end
                    end
                end
            catch
                disp("Warning! Error during IO closing!");
            end
        end

        function delete(obj)
            closeCon(obj);
        end
    end

    %% ----------Protocol description----------
    %{
    % Protocol: (symbol '-' before code is shift position of this code)
    % Package send format:
    % '<' - Package begin
    %%%%%%%%%%%%%%%%%%%%
    % -'D' - Receive data
    % --'P' - Part of data
    % ---'A' - Joint angels
    % ---'J' - Joints data (carthesian data)
    % ----'V' - Joints coords
    % ----'C' - Joints coordinate system
    % ---'F' - Force data
    % ----'F' - Force data from Flange
    % ----'T' - Force data from EEF
    % ---'D' - Debug container
    % --'K' - Kinematics data
    % ---'F' - Forward Kinematics
    % ---'I' - Inverce Kinematics
    %%%%%%%%%%%%%%%%%%%%%
    % -'M' - Move robot
    % --'B' - Batch move
    % --'S' - Spline move
    % --'J' - SplineJP move
    % ---int_number - package size, count packages
    % ----{unit8 type and data type, uint32 flags, N double numbers - coord and e.t., additional double data } x N times
    % {uint8 - 0000  0000} {uint32 - 0000 ...  0000}
    % {        type dtype} {          flags   }
    % type - 0001 - PTP, 0010 - LIN, 0011 - SPL, 1010 - Rel LIN, 1011 - Rel SPL
    % dtype - 0011 - coords only, 0110 - coords and orient, 0111 - coords,
    %orient and redundancy
    % flags - 0000 0001 - add vel, 0000 0010 - add acc
    %%%%%%%%%%%%%%%%%%%%%
    % -'C' - Control functions
    % --'T' - Tool operations
    % ---'D' - Deattach current tool
    % ---'A' - Attach tool
    % ----{int32 strlen, string_name_of_tool}
    % ---'C' - Current tool
    % ---'F' - List of all frames on tool
    % ---'S' - Set new motion frame
    % ---'N' - Attach new tool
    % --'W' - Workpiece operatons - Not Implemented
    % ---'D' - Deattach current Workpiece
    % ---'A' - Attach Workpiece
    % ----uint8_number - Number of Workpiece, hardcoded
    % --'O' - Output operations
    % ---'S' - Set state
    % ----int_number - Number of input
    % -----4_byte_number(up_to) - State of output
    % ---'R' - Read state
    % ----int_number - Number of input
    % --'I' - Input operations
    % ---'R' - Read input states
    % --'C' - Connection functions
    % ---'C' - Check connection
    %%%%%%%%%%%%%%%%%%%%%
    % -'I' - Information functions
    % --'P' - Get List of saved frames
    % --'I' - Get List of IO ports
    % --'N' - Get name of...
    % ---'C' - Contoller
    % ---'R' - Robot
    % ---'T' - Tools
    % ---'W' - Workpieses - Not Implemented
    % ---'O' - Objects - Not Implemented
    % --'T' - Transformation of EEF from flange
    % ---'A' - Eyler angle
    % ---'V' - Vector
    %}
end

