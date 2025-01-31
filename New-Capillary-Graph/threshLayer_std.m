classdef threshLayer_std < nnet.layer.Layer
    % Example custom PReLU layer.

    
    methods
        function layer = threshLayer_std(name) 


            % Set layer name.
            layer.Name = name;
            %layer.Description = "PReLU with

        end
        
        function Z = predict(layer, X)
            % Z = predict(layer, X) forwards the input data X through the
            % layer and outputs the result Z.
           
            Z = X;
            Z = max(Z,0.01);
%             Z(1,:) = squeeze(X(:,:,1,:));
%             X2 = squeeze(X(:,:,2,:));
%             X2(X2<0.01) = 0.01;
%             
%            	Z(2,:) = X2;%reshape(squeeze(),1,1,1,size(X,4)); 
%             
%             Z = reshape(Z, 1 ,1,2,size(X,4));

          
        end
    end
end