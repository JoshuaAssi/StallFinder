classdef Uncertainty_layer < nnet.layer.RegressionLayer

    
    properties(Constant)
        % Small constant to prevent division by zero. 
        Epsilon = 1e-8;
    end
    
    methods
        
        function layer = Uncertainty_layer(name)
            % layer =  dicePixelClassification3dLayer(name) creates a Dice
            % pixel classification layer with the specified name.
            
            % Set layer name.          
            layer.Name = name;
            
            % Set layer description.
            layer.Description = 'Uncertainty layer';
        end
        
        
        function loss = forwardLoss(layer, Y, T)
            % loss = forwardLoss(layer, Y, T) returns the Dice loss between
            % the predictions Y and the training targets T. 
            eps = 1e-8;
           % Y = single(Y>0.5);
           %Y = squeeze(Y);
           Y1 = Y(:,:,1,:); 
           Y2 = Y(:,:,2,:); 
           


            %[squeeze(Y1) squeeze(Y2) squeeze(T(:,:,1,:))]
            %T = T(:,:,1,:);
            %-log(1./(Y2.*sqrt(2*pi)).*exp(-1/2*(T(:,:,1,:)-Y1).^2./Y2.^2))
            
            loss = mean(-log(1./(Y2.*sqrt(2*pi)).*exp(-1/2*(T(:,:,1,:)-Y1).^2./Y2.^2)),4);
            

            
         
        end
%         


         function dLdY = backwardLoss(layer, Y, T)
%             % dLdY = backwardLoss(layer, Y, T) returns the derivatives of
%             % the Dice loss with respect to the predictions Y.
%             
%            
                
                Y1 = Y(:,:,1,:);
                Y2 = Y(:,:,2,:);
                
                
                dLdY(1,:) = squeeze((Y1-T(:,:,1,:))./Y2.^2);
                dLdY(2,:) = -squeeze((T(:,:,1,:).^2 - 2*T(:,:,1,:).*Y1 + Y1.^2 - Y2.^2)./Y2.^3);
               
                dLdY = reshape(dLdY, 1,1,2,size(Y1,4));
               
         end
    end
end