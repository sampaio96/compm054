function r=practicalMixGaussB

%The goal of this practical is to generate some data from a one-dimensional
%mixtures of Gaussians model, and subsequently to fit a mixtures of Gaussians model to
%this data, to recover the original parameters.

%You should use this template for your code and fill in the missing 
%sections marked "TO DO"

%close all open plots
close all;




% TO DO: Note (again) that you should NOT be using functions like normpdf and
% normfit or other functions from Statistics Toolbox in sampling from or
% fitting your distributions in this or further parts of this practical.
% Optionally, you can try comparing your results to those produced by those
% functions, but our goal here is to learn what is happening!





%define the True parameters for mixture of k Gaussians
%we will represent the mixtures of Gaussians as a Matlab structure
%we are working in 1 dimension, but if we were in d dimensions, the mean field
%would be a dxk matrix and the cov field would be a dxdxk matrix.
mixGaussTrue.k = 2;
mixGaussTrue.d = 1;
mixGaussTrue.weight = [0.3 0.7];
mixGaussTrue.mean = [-1 1.5];
mixGaussTrue.cov = reshape([0.5 0.25],1,1,2);

%define number of samples to generate
nData = 400;

%generate data from the mixture of Gaussians
%TO DO - fill in this routine (below)
data = mixGaussGen1d(mixGaussTrue,nData);

%draw data, True Gaussians
figure;
drawEMData1d(data,mixGaussTrue);
drawnow;

%define number of components to estimate
nGaussEst = 2;

%fit mixture of Gaussians (Pretend someone handed you some data. Now what?)
%TO DO fill in this routine (below)
figure;
mixGaussEst = fitMixGauss1d(data,nGaussEst);

%==========================================================================
%==========================================================================

%the goal of this function is to generate data from a one-dimensional
%mixture of Gaussians structure.
function data = mixGaussGen1d(mixGauss,nData);

%create space for output data
data = zeros(1,nData);
%for each data point
for (cData = 1:nData)
    %randomly choose Gaussian according to probability distributions
    h = sampleFromDiscrete(mixGauss.weight); % choose 1 or 2
    %draw a sample from the appropriate Gaussian distribution
    %TO DO (d)
    data(:,cData) = sqrt(mixGauss.cov(:,:,h)) * randn(1) + mixGauss.mean(h);
end;
    
%==========================================================================
%==========================================================================

function mixGaussEst = fitMixGauss1d(data,k)
        
nData = size(data,2);

%MAIN E-M ROUTINE 
%there are nData data points, and there is a hidden variable associated
%with each.  If the hidden variable is 0 this indicates that the data was
%generated by the first Gaussian.  If the hidden variable is 1 then this
%indicates that the hidden variable was generated by the second Gaussian
%etc.

responsibilities = zeros(k, nData);

%in the E-M algorithm, we calculate a complete posterior distribution over
%the (nData) hidden variables in the E-Step.  In the M-Step, we
%update the parameters of the Gaussians (mean, cov, w).  

%we will initialize the values to random values
mixGaussEst.d = 1;
mixGaussEst.k = k;
mixGaussEst.weight = (1/k)*ones(1,k);
mixGaussEst.mean = 2*randn(1,k);
mixGaussEst.cov = 0.1+1.5*rand(1,1,k);

%calculate current likelihood
%TO DO - fill in this routine
logLike = getMixGaussLogLike(data,mixGaussEst);
fprintf('Log Likelihood Iter 0 : %4.3f\n',logLike);

nIter = 20;
for (cIter = 1:nIter)
  
   % ===================== =====================
   %Expectation step
   % ===================== =====================
   for (cData = 1:nData)
        %TO DO: fill in column of 'hidden' - calculate posterior probability that
        %this data point came from each of the Gaussians
        %replace this:
        ll = zeros(1,k);
        thisdata = data(:,cData);
        for cGauss=1:k
            ll(cGauss) = mixGaussEst.weight(cGauss) * 1/((2*pi)^(mixGaussEst.d/2)*(norm(mixGaussEst.cov(:,:,cGauss)))^(1/2))*exp(-0.5*((thisdata-mixGaussEst.mean(cGauss)).')*inv(mixGaussEst.cov(:,:,cGauss))*(thisdata-mixGaussEst.mean(cGauss)));
            % mixGaussEst.weight(cGauss) * mvnpdf(data(:,cData),mixGaussEst.mean(cGauss),mixGaussEst.cov(cGauss));
        end
        
        for cGauss=1:k
            responsibilities(cGauss,cData) = ll(cGauss) ./ sum(ll);
        end
   end;
   
   %calculate the log likelihood
   logLike = getMixGaussLogLike(data,mixGaussEst);
   fprintf('Log Likelihood After E-Step Iter %d : %4.3f\n',cIter,logLike);

   %calculate the bound
   %TO DO - Fill in this routine
   bound = getMixGaussBound(data,mixGaussEst,responsibilities);
   fprintf('Bound After E-Step Iter %d : %4.3f\n',cIter,bound);

   % ===================== =====================
   %Maximization Step
   % ===================== =====================
   %for each constituent Gaussian
   for (cGauss = 1:k) 
        %TO DO:  Update weighting parameters mixGauss.weight based on the total
        %posterior probability associated with each Gaussian. Replace this:
        sumIr = sum(responsibilities(cGauss,:));
        
        mixGaussEst.weight(cGauss) = sumIr/sum(sum(responsibilities(:,:)));
   
        %TO DO:  Update mean parameters mixGauss.mean by weighted average
        %where weights are given by posterior probability associated with
        %Gaussian.  Replace this:
        ji = responsibilities(cGauss,:) .* data(:,:);
        mixGaussEst.mean(cGauss) = sum(ji) ./ sumIr;
        
        %TO DO:  Update covariance parameter based on weighted average of
        %square distance from update mean, where weights are given by
        %posterior probability associated with Gaussian
        jj = data - mixGaussEst.mean(:,cGauss);
        jk = zeros(1,1,nData);
        for i=1:nData
            jk(1,1,i) = jj(1,i) * jj(1,i).' * responsibilities(cGauss,i);
        end
        mixGaussEst.cov(1,1,cGauss) = sum(jk,3) ./ sumIr;
   end;
   
   %draw the new solution
   drawEMData1d(data,mixGaussEst);drawnow;

   %calculate the log likelihood
   logLike = getMixGaussLogLike(data,mixGaussEst);
   fprintf('Log Likelihood After M-Step Iter %d : %4.3f\n',cIter,logLike);

   %calculate the bound
   bound = getMixGaussBound(data,mixGaussEst,responsibilities);
   fprintf('Bound After M-Step Iter %d : %4.3f\n',cIter,bound);   
end;

%==========================================================================
%==========================================================================

%the goal of this routine is to calculate the log likelihood for the whole
%data set under a mixture of Gaussians model. We calculate the log because the
%likelihood will probably be a very small number that Matlab may not be
%able to represent.
function logLike = getMixGaussLogLike(data,mixGaussEst);

%find total number of data items
nData = size(data,2);

%initialize log likelihoods
logLike = 0;

%run through each data item
for(cData = 1:nData)
    thisData = data(:,cData);    
    %TO DO (e) - calculate likelihood of this data point under mixture of
    %Gaussians model. Replace this
    
    nDim = length(thisData);
    % assert(eq(nDim,mixGaussEst.d));
    like = 0;
    for(cGauss = 1:mixGaussEst.k)
        like = like + mixGaussEst.weight(cGauss) * 1/((2*pi)^(nDim/2)*(norm(mixGaussEst.cov(:,:,cGauss)))^(1/2)) * exp(-0.5*((thisData-mixGaussEst.mean(cGauss)).')*inv(mixGaussEst.cov(:,:,cGauss))*(thisData-mixGaussEst.mean(cGauss)));
    end
    
    %add to total log like
    logLike = logLike+log(like);        
end;

%==========================================================================
%==========================================================================

%the goal of this routine is to calculate the bound on the 
%log likelihood for the whole data set under a mixture of Gaussians model.
function bound = getMixGaussBound(data,mixGaussEst,responsibilities)

%find total number of data items
nData = size(data,2);

%initialize bound
bound = 0;

%run through each data item
for(cData = 1:nData)
    %extract this data
    thisData = data(:,cData);    
    %extract this q(h)
    thisQ = responsibilities(:,cData);
    
    nDim = length(thisData);
    assert(eq(nDim,mixGaussEst.d));
    
    %TO DO - calculate contribution to bound of this datapoint
    %Replace this
    boundValue = 0;    
    for(cGauss = 1:mixGaussEst.k)
        boundValue = boundValue + thisQ(cGauss) * log ( (mixGaussEst.weight(cGauss) * 1/((2*pi)^(nDim/2)*(norm(mixGaussEst.cov(:,:,cGauss)))^(1/2)) * exp(-0.5*((thisData-mixGaussEst.mean(cGauss)).')*inv(mixGaussEst.cov(:,:,cGauss))*(thisData-mixGaussEst.mean(cGauss)))) / thisQ(cGauss));
    end
    
    %add to total log like
    bound = bound+boundValue;
end;

%==========================================================================
%==========================================================================

%The goal fo this routine is to draw the data in histogram form and plot
%the mixtures of Gaussian model on top of it.
function r = drawEMData1d(data,mixGauss)

%delete previous plot if it exists
hold off;
%bin the data to make a histogram
binWidth = 0.1;
binMin =-4;
binMax = 4;
xHist = binMin:binWidth:binMax;
yHist = hist(data,xHist)/(length(data)*binWidth);
bar(xHist,yHist,1);
%retain this plot
hold on;
%calculate Gaussian data
nGauss = mixGauss.k;
gaussEnvEst = zeros(size(xHist));
for (cGauss = 1:nGauss)
    %calculate weighted Gaussian values
    gaussProb = mixGauss.weight(cGauss)*getGaussProb(xHist,mixGauss.mean(cGauss),mixGauss.cov(cGauss));
    plot(xHist, gaussProb,'m-');
    %add to form envelope
    gaussEnvEst = gaussEnvEst+gaussProb;
end;
plot(xHist, gaussEnvEst,'g-');

%tidy up plot
xlabel('Data Value');
ylabel('Probability Density');
set(gca,'Box','Off');
set(gcf,'Color',[1 1 1]);
xlim([binMin binMax]);
ylim([0 max(yHist)*1.5]);

%==========================================================================
%==========================================================================

%draws a random sample from a discrete probability distribution using a
%rejection sampling method
function r = sampleFromDiscrete(probDist);

nIndex = length(probDist);
while(1)
    %choose random index
    r=ceil(rand(1)*nIndex);
    %choose random height
    randHeight = rand(1);
    %if height is less than probability value at this point in the
    %histogram then select
    if (randHeight<probDist(r))
        break;
    end;
end;
    
%==========================================================================
%==========================================================================

%subroutine to return gaussian probabilities
function prob = getGaussProb(x,mean,var)

prob = exp(-0.5*((x-mean).^2)/(var));
prob = prob/ sqrt(2*pi*var);
