%% 光源検索プログラム
%照明環境の輝度データから数とサイズを返す
%光源

function num=sizenumber(A,pixel)%%出力は後で変える(num)
[height,width]=size(A);
num=0;%数
er=10;%%判断するピクセルの大きさ
kensaku=zeros(2,pixel);%検索格納用

B=zeros(height+er*2,width+er*2);
B(1+er:er+height,1+er:er+width)=A;

for i=1+er:er+height
for j=1+er:er+width
        
        if(B(i,j))%照明を見つけたら

            num=num+1;
            B(i,j)=0;%見つけたのでフラグを折る
            [B,kensaku]=syuu(B,kensaku,i,j,er);     
            
            
         for i2=1:pixel
%              if i2==pixel
%                  disp('a')
%              end
             if kensaku(1,i2)==0
                 break
             end
         [B,kensaku]=syuu(B,kensaku,kensaku(1,i2),kensaku(2,i2),er);
         
         end
         
         
         
        end
        
        kensaku=zeros(2,pixel);%検索格納用
end
end
end





function [B,kensaku]=syuu(B,kensaku,i,j,t)%%周りにある1を探し、見つけたら検索格納に入れる

                       
                    [a,b]=find(B(i-t:i+t,j-t:j+t));
                    a=a+i-1-t;
                    b=b+j-1-t;
                    kazu=nnz(a);
                       B(i-t:i+t,j-t:j+t)=zeros(2*t+1,2*t+1);%フラグを折る
                       basho=nnz(kensaku(1,:));%場所を調べる
                       kensaku(:,basho+1:basho+kazu)=[a.';b.'];




end
