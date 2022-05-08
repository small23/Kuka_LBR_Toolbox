classdef JavaMethodWrapper
    %Wrapper class for a Java method or constructor reflection object.
    %Allows passing arrays of primitive type by reference from MATLAB by
    %enclosing them in an Object[] (via a List) which is then passed to
    %invoke/newInstance.
    %Copyright 2020 Benjamin P Davis
    
    properties(SetAccess = protected, GetAccess = public)
        %the java.lang.Class associated with the method
        method_class
        %java.lang.reflect.Method which corresponds to the method
        %or java.lang.reflect.Constructor which corresponds to the
        %constructor
        inner_method
    end
    
    properties(Constant, Access = protected)
        %A list of all the java primitive types
        primitiveNames = {'byte', 'char', 'double', 'float', ...
            'int', 'long', 'short', 'boolean'}
        %The java.lang.Class type objects for primitives corresponding to
        %primitiveNames.
        primitiveTypes = [...
            java.lang.Byte.TYPE
            java.lang.Character.TYPE
            java.lang.Double.TYPE
            java.lang.Float.TYPE
            java.lang.Integer.TYPE
            java.lang.Long.TYPE
            java.lang.Short.TYPE
            java.lang.Boolean.TYPE
        ]
        %The array type codes for primitives corresponding to
        %primitiveNames.
        %See https://docs.oracle.com/javase/specs/jvms/se7/html/jvms-4.html#jvms-4.3.2
        primitiveCodes = 'BCDFIJSZ'
    end
    
    methods(Static)
        function obj = JavaMethodWrapper(varargin)
            %JavaMethodWrapper(javaClass,methodSignature)
            %Create a JavaMethodWrapper corresponding to the class and
            %methods specified.
            %   javaClass - Class object or char/string naming the class
            %   methodSignature - name of the method plus argument types in
            %       the manner shown by methods -full or methodsview, i.e
            %       'read(byte[], int, int)' or 'equals(java.lang.Object)'.
            %       It is not required to include return type or any other 
            %       leading modifiers (e.g. static). These leading
            %       expressions will be trimmed before setting
            %       this.signature.
            if nargin > 0
                [javaClass,signature] = deal(varargin{:});
                
                classObj = javaClass.getClass();

                obj.method_class = classObj;
                [name,types] = JavaMethodWrapper.translateSignature(signature);
                obj.inner_method = classObj.getMethod(name, types);
            end
        end
    end

    methods(Static, Access = protected)
        function [name,types] = translateSignature(signature)
            %Translate a method signature of the format
            %name(argtype1,..., argtypeN) to a name and java.lang.Class[] 
            %for use in java.lang.Class getMethod.
            
            %verify the method name is in correct format, and remove return
            %type or any other leading/trailing modifiers such as static,
            %synchronized, throws, etc.
            signature = regexp(signature, ...
                '[^ ]+[ ]*\([^\)]*\)', 'match', 'once');
            if isempty(signature)
                error('JavaMethodWrapper:invalid_signature', ...
                    'Invalid method signature');
            end
            %remove extraneous spaces
            %split the name on parentheses and comma
            parts = strsplit(signature, {',', '(', ')'});
            parts = parts(~cellfun('isempty', parts));
            %the first part is the name, second and further are arg types
            name = parts{1};
            parts = parts(2:end);
            types = javaArray('java.lang.Class', length(parts));
            for iP = 1:length(parts)
                part = strtrim(parts{iP});
                %pull off the type name and any array brackets after
                tok = regexp(part, '^([^\[ ]+)(\[\])*', 'tokens', 'once');
                if isempty(tok)
                    error('JavaMethodWrapper:invalid_signature', ...
                        'Invalid method signature');
                end
                type_name = tok{1};
                brackets = tok{2};
                %count the bracket pairs
                n_pairs = length(brackets)/2;
                is_primitive = strcmp(type_name, JavaMethodWrapper.primitiveNames);
                
                if n_pairs == 0
                    %non-array case
                    if any(is_primitive)
                        %if it is a primitive type, there are special 
                        %classes that contain the the Class object for the 
                        %type
                        types(iP) = JavaMethodWrapper.primitiveTypes(is_primitive);
                    else
                        %for a general reference type we can use forName to
                        %get the Class
                        types(iP) = java.lang.Class.forName(type_name);
                    end
                else
                    %array case
                    %We will use forName with the correct number of
                    %preceding brackets for array dimension.
                    %Note the internal notation uses only one bracket per
                    %dimension.
                    %e.g. byte[] -> [B
                    prefix = repmat('[', 1, n_pairs);
                    if any(is_primitive)
                        %primitive arrays are given using a single letter
                        %code after the brackets
                        type_name = [prefix ...
                            JavaMethodWrapper.primitiveCodes(is_primitive)];
                    else
                        %reference types have the format [LtypeName;
                        type_name = [prefix 'L' type_name ';']; %#ok<AGROW>
                    end
                    types(iP) = java.lang.Class.forName(type_name);
                end                    
            end
        end
    end
end