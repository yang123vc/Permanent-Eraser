FasdUAS 1.101.10   ��   ��    l     ����  O         k   �     	  r    	 
  
 1    ��
�� 
vers  o      ���� 0 
os_version   	     l  
 
��������  ��  ��        Z   
�  ��   @   
     o   
 ���� 0 
os_version    m       @$������  k   �       l   ��  ��    < 6	display dialog "You are running Mac OS " & os_version     �   l 	 d i s p l a y   d i a l o g   " Y o u   a r e   r u n n i n g   M a c   O S   "   &   o s _ v e r s i o n      l   ��������  ��  ��        r       !   n     " # " 1    ��
�� 
psxp # l    $���� $ I   �� %��
�� .earsffdralis        afdr % m    ��
�� afdmcusr��  ��  ��   ! o      ���� 0 user_folder     & ' & r     ( ) ( b     * + * o    ���� 0 user_folder   + m     , , � - - L L i b r a r y / W o r k f l o w s / A p p l i c a t i o n s / F i n d e r / ) o      ���� 0 automator_folder   '  . / . r     % 0 1 0 b     # 2 3 2 o     !���� 0 user_folder   3 m   ! " 4 4 � 5 5 " L i b r a r y / S e r v i c e s / 1 o      ���� 0 services_folder   /  6 7 6 l  & &��������  ��  ��   7  8 9 8 l  & &�� : ;��   : A ;		display dialog "Home directory: " & (user_folder as text)    ; � < < v 	 	 d i s p l a y   d i a l o g   " H o m e   d i r e c t o r y :   "   &   ( u s e r _ f o l d e r   a s   t e x t ) 9  = > = l  & &�� ? @��   ? I C		display dialog "Services Directory: " & (services_folder as text)    @ � A A � 	 	 d i s p l a y   d i a l o g   " S e r v i c e s   D i r e c t o r y :   "   &   ( s e r v i c e s _ f o l d e r   a s   t e x t ) >  B C B l  & &��������  ��  ��   C  D E D l  & &�� F G��   F = 7	set the_folder to (folder of the front window) as text    G � H H n 	 s e t   t h e _ f o l d e r   t o   ( f o l d e r   o f   t h e   f r o n t   w i n d o w )   a s   t e x t E  I J I r   & / K L K c   & - M N M l  & + O���� O I  & +�� P��
�� .earsffdralis        afdr P  f   & '��  ��  ��   N m   + ,��
�� 
utxt L o      ���� 0 
cwd_folder   J  Q R Q r   0 5 S T S b   0 3 U V U o   0 1���� 0 
cwd_folder   V m   1 2 W W � X X & C o n t e n t s : R e s o u r c e s : T o      ���� 0 rsrc_folder   R  Y Z Y r   6 F [ \ [ c   6 B ] ^ ] l  6 @ _���� _ n   6 @ ` a ` m   < @��
�� 
ctnr a 4   6 <�� b
�� 
cobj b o   : ;���� 0 
cwd_folder  ��  ��   ^ m   @ A��
�� 
utxt \ o      ���� 0 parent_folder   Z  c d c r   G T e f e c   G P g h g l  G L i���� i I  G L�� j��
�� .earsffdralis        afdr j m   G H��
�� afdmcusr��  ��  ��   h m   L O��
�� 
ctxt f o      ���� 0 home_folder   d  k l k l  U U�� m n��   m 4 . set posix_path to POSIX path of parent_folder    n � o o \   s e t   p o s i x _ p a t h   t o   P O S I X   p a t h   o f   p a r e n t _ f o l d e r l  p q p l  U U��������  ��  ��   q  r s r l  U U�� t u��   t &   set the clipboard to the_folder    u � v v @   s e t   t h e   c l i p b o a r d   t o   t h e _ f o l d e r s  w x w l  U U�� y z��   y    display dialog the_folder    z � { { 4   d i s p l a y   d i a l o g   t h e _ f o l d e r x  | } | l  U U�� ~ ��   ~ 6 0 display dialog "Parent folder " & parent_folder     � � � `   d i s p l a y   d i a l o g   " P a r e n t   f o l d e r   "   &   p a r e n t _ f o l d e r }  � � � l  U U�� � ���   � ! 		display dialog posix_path    � � � � 6 	 	 d i s p l a y   d i a l o g   p o s i x _ p a t h �  � � � l  U U��������  ��  ��   �  � � � Z   U� � ��� � � @   U Z � � � o   U V���� 0 
os_version   � m   V Y � � @%333333 � k   ] � � �  � � � l  ] ]��������  ��  ��   �  � � � l  ] ]�� � ���   � @ : These next four lines work properly and are what you need    � � � � t   T h e s e   n e x t   f o u r   l i n e s   w o r k   p r o p e r l y   a n d   a r e   w h a t   y o u   n e e d �  � � � l  ] ]�� � ���   � ? 9 set home_folder to (path to current user folder) as text    � � � � r   s e t   h o m e _ f o l d e r   t o   ( p a t h   t o   c u r r e n t   u s e r   f o l d e r )   a s   t e x t �  � � � r   ] h � � � b   ] d � � � o   ] `���� 0 home_folder   � m   ` c � � � � �  L i b r a r y : � o      ���� 0 library_folder   �  � � � r   i r � � � b   i p � � � o   i l���� 0 library_folder   � m   l o � � � � �  S e r v i c e s : � o      ���� 0 services_folder   �  � � � r   s | � � � b   s x � � � o   s t���� 0 rsrc_folder   � m   t w � � � � �  E r a s e . w o r k f l o w � o      ���� 0 src_file   �  � � � l  } }�� � ���   � 7 1 set src_file to parent_folder & "Erase.workflow"    � � � � b   s e t   s r c _ f i l e   t o   p a r e n t _ f o l d e r   &   " E r a s e . w o r k f l o w " �  � � � l  } }��������  ��  ��   �  � � � l  } }��������  ��  ��   �  � � � Z   } � � ����� � =  } � � � � l  } � ����� � I  } ��� ���
�� .coredoexbool        obj  � 4   } ��� �
�� 
cfol � o   � ����� 0 services_folder  ��  ��  ��   � m   � ���
�� boovfals � I  � ����� �
�� .corecrel****      � null��   � �� � �
�� 
kocl � m   � ���
�� 
cfol � �� � �
�� 
insh � o   � ����� 0 library_folder   � �� ���
�� 
prdt � K   � � � � �� ���
�� 
pnam � m   � � � � � � �  S e r v i c e s��  ��  ��  ��   �  � � � l  � ���������  ��  ��   �  � � � I  � ��� � �
�� .coreclon****      � **** � 4   � ��� �
�� 
file � o   � ����� 0 src_file   � �� � �
�� 
insh � 4   � ��� �
�� 
cfol � o   � ����� 0 services_folder   � �� ���
�� 
alrp � m   � ���
�� boovtrue��   �  � � � l  � ���������  ��  ��   �  � � � I  � ��� ���
�� .sysodlogaskr        TEXT � b   � � � � � m   � � � � � � � v T h e   f i l e   E r a s e . w o r k f l o w   h a s   b e e n   i n s t a l l e d   i n t o   t h e   f o l d e r   � o   � ����� 0 services_folder  ��   �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   � G A set source_file to file "Erase.workflow" of folder parent_folder    � � � � �   s e t   s o u r c e _ f i l e   t o   f i l e   " E r a s e . w o r k f l o w "   o f   f o l d e r   p a r e n t _ f o l d e r �  � � � l  � �� � ��   � T N set dest_folder to folder "Library:Services" of (path to current user folder)    � � � � �   s e t   d e s t _ f o l d e r   t o   f o l d e r   " L i b r a r y : S e r v i c e s "   o f   ( p a t h   t o   c u r r e n t   u s e r   f o l d e r ) �  � � � l  � ��~�}�|�~  �}  �|   �  � � � l  � ��{ � ��{   � E ?			display dialog "Source File: " & source_file as Unicode text    � � � � ~ 	 	 	 d i s p l a y   d i a l o g   " S o u r c e   F i l e :   "   &   s o u r c e _ f i l e   a s   U n i c o d e   t e x t �  � � � l  � ��z � ��z   � C = display dialog "Source file: " & source_file as Unicode text    � � � � z   d i s p l a y   d i a l o g   " S o u r c e   f i l e :   "   &   s o u r c e _ f i l e   a s   U n i c o d e   t e x t �  � � � l  � ��y � �y   � C = display dialog "Dest Folder: " & dest_folder as Unicode text     � z   d i s p l a y   d i a l o g   " D e s t   F o l d e r :   "   &   d e s t _ f o l d e r   a s   U n i c o d e   t e x t �  l  � ��x�w�v�x  �w  �v    l  � ��u�u   &   copy source_file to dest_folder    � @   c o p y   s o u r c e _ f i l e   t o   d e s t _ f o l d e r 	
	 l  � ��t�s�r�t  �s  �r  
  l  � ��q�q   J Dset source_file to (path to current user folder) & "Desktop:foo.txt"    � � s e t   s o u r c e _ f i l e   t o   ( p a t h   t o   c u r r e n t   u s e r   f o l d e r )   &   " D e s k t o p : f o o . t x t "  l  � ��p�p     install Service    �     i n s t a l l   S e r v i c e  l  � ��o�o   J D copy POSIX file source_file to folder (path to current user folder)    � �   c o p y   P O S I X   f i l e   s o u r c e _ f i l e   t o   f o l d e r   ( p a t h   t o   c u r r e n t   u s e r   f o l d e r )  l  � ��n�n   A ;			set dest_folder to quoted form of folder services_folder    � v 	 	 	 s e t   d e s t _ f o l d e r   t o   q u o t e d   f o r m   o f   f o l d e r   s e r v i c e s _ f o l d e r   l  � ��m!"�m  ! E ?			display dialog "Dest Folder: " & dest_folder as Unicode text   " �## ~ 	 	 	 d i s p l a y   d i a l o g   " D e s t   F o l d e r :   "   &   d e s t _ f o l d e r   a s   U n i c o d e   t e x t  $%$ l  � ��l�k�j�l  �k  �j  % &�i& l  � ��h'(�h  ' 8 2			copy file source_file to folder services_folder   ( �)) d 	 	 	 c o p y   f i l e   s o u r c e _ f i l e   t o   f o l d e r   s e r v i c e s _ f o l d e r�i  ��   � l  ��*+,* k   ��-- ./. l  � ��g01�g  0 K E Install Automator Action in ~/Library/Workflows/Applications/Finder/   1 �22 �   I n s t a l l   A u t o m a t o r   A c t i o n   i n   ~ / L i b r a r y / W o r k f l o w s / A p p l i c a t i o n s / F i n d e r // 343 l  � ��f�e�d�f  �e  �d  4 565 r   � �787 b   � �9:9 o   � ��c�c 0 home_folder  : m   � �;; �<<  L i b r a r y :8 o      �b�b 0 library_folder  6 =>= r   � �?@? b   � �ABA o   � ��a�a 0 home_folder  B m   � �CC �DD $ L i b r a r y : W o r k f l o w s :@ o      �`�` 0 workflows_folder  > EFE r   � �GHG b   � �IJI o   � ��_�_ 0 home_folder  J m   � �KK �LL > L i b r a r y : W o r k f l o w s : A p p l i c a t i o n s :H o      �^�^ 0 apps_folder  F MNM r   �OPO b   �QRQ o   � �]�] 0 home_folder  R m   SS �TT L L i b r a r y : W o r k f l o w s : A p p l i c a t i o n s : F i n d e r :P o      �\�\ 0 finder_folder  N UVU l 		�[�Z�Y�[  �Z  �Y  V WXW Z  	<YZ�X�WY = 	[\[ l 	]�V�U] I 	�T^�S
�T .coredoexbool        obj ^ 4  	�R_
�R 
cfol_ o  �Q�Q 0 workflows_folder  �S  �V  �U  \ m  �P
�P boovfalsZ I 8�O�N`
�O .corecrel****      � null�N  ` �Mab
�M 
kocla m  !�L
�L 
cfolb �Kcd
�K 
inshc o  $'�J�J 0 library_folder  d �Ie�H
�I 
prdte K  *2ff �Gg�F
�G 
pnamg m  -0hh �ii  W o r k f l o w s�F  �H  �X  �W  X jkj l ==�E�D�C�E  �D  �C  k lml Z  =pno�B�An = =Kpqp l =Ir�@�?r I =I�>s�=
�> .coredoexbool        obj s 4  =E�<t
�< 
cfolt o  AD�;�; 0 apps_folder  �=  �@  �?  q m  IJ�:
�: boovfalso I Nl�9�8u
�9 .corecrel****      � null�8  u �7vw
�7 
koclv m  RU�6
�6 
cfolw �5xy
�5 
inshx o  X[�4�4 0 workflows_folder  y �3z�2
�3 
prdtz K  ^f{{ �1|�0
�1 
pnam| m  ad}} �~~  A p p l i c a t i o n s�0  �2  �B  �A  m � l qq�/�.�-�/  �.  �-  � ��� Z  q����,�+� = q��� l q}��*�)� I q}�(��'
�( .coredoexbool        obj � 4  qy�&�
�& 
cfol� o  ux�%�% 0 finder_folder  �'  �*  �)  � m  }~�$
�$ boovfals� I ���#�"�
�# .corecrel****      � null�"  � �!��
�! 
kocl� m  ��� 
�  
cfol� ���
� 
insh� o  ���� 0 apps_folder  � ���
� 
prdt� K  ���� ���
� 
pnam� m  ���� ���  F i n d e r�  �  �,  �+  � ��� l ������  �  �  � ��� Z  ������� = ����� l ������ I �����
� .coredoexbool        obj � 4  ����
� 
cfol� o  ���� 0 finder_folder  �  �  �  � m  ���
� boovtrue� k  ���� ��� r  ����� b  ����� o  ���� 0 rsrc_folder  � m  ���� ��� 2 P e r m a n e n t   E r a s e r . w o r k f l o w� o      �� 0 src_file  � ��� l ������  � B < set src_file to parent_folder & "Permanent Eraser.workflow"   � ��� x   s e t   s r c _ f i l e   t o   p a r e n t _ f o l d e r   &   " P e r m a n e n t   E r a s e r . w o r k f l o w "� ��� l ���
�	��
  �	  �  � ��� I �����
� .coreclon****      � ****� 4  ����
� 
file� o  ���� 0 src_file  � ���
� 
insh� 4  ����
� 
cfol� o  ���� 0 finder_folder  � ��� 
� 
alrp� m  ����
�� boovtrue�   � ��� l ����������  ��  ��  � ��� I �������
�� .sysodlogaskr        TEXT� b  ����� m  ���� ��� � T h e   f i l e   P e r m a n e n t   E r a s e r . w o r k f l o w   h a s   b e e n   i n s t a l l e d   i n t o   t h e   f o l d e r  � o  ������ 0 finder_folder  ��  � ���� l ����������  ��  ��  ��  �  �  � ��� l ��������  � ] W set target_folder to (make new folder at home_folder with properties {name:temp_name})   � ��� �   s e t   t a r g e t _ f o l d e r   t o   ( m a k e   n e w   f o l d e r   a t   h o m e _ f o l d e r   w i t h   p r o p e r t i e s   { n a m e : t e m p _ n a m e } )� ��� l ��������  � i c make new folder at alias "Macintosh HD:Users:user:Desktop:" with properties {name:"Test Folder 2"}   � ��� �   m a k e   n e w   f o l d e r   a t   a l i a s   " M a c i n t o s h   H D : U s e r s : u s e r : D e s k t o p : "   w i t h   p r o p e r t i e s   { n a m e : " T e s t   F o l d e r   2 " }� ��� l ��������  � E ? if (exists folder new_foldername of this_folder) is false then   � ��� ~   i f   ( e x i s t s   f o l d e r   n e w _ f o l d e r n a m e   o f   t h i s _ f o l d e r )   i s   f a l s e   t h e n� ��� l ��������  � L F  make new folder at this_folder with properties {name:new_foldername}   � ��� �     m a k e   n e w   f o l d e r   a t   t h i s _ f o l d e r   w i t h   p r o p e r t i e s   { n a m e : n e w _ f o l d e r n a m e }� ��� l ��������  �   end if   � ���    e n d   i f� ���� l ����������  ��  ��  ��  +   for Mac OS 10.4 and 10.5   , ��� 2   f o r   M a c   O S   1 0 . 4   a n d   1 0 . 5 � ��� l ����������  ��  ��  � ���� l ����������  ��  ��  ��  ��    I �������
�� .sysodlogaskr        TEXT� m  ���� ��� j N o   p l u g - i n s   a r e   a v a i l a b l e   f o r   y o u r   v e r s i o n   o f   M a c   O S .��    ���� l ����������  ��  ��  ��    m     ���                                                                                  MACS  alis    r  Snow Leopard               ��x�H+    �
Finder.app                                                       �	Ƙ�        ����  	                CoreServices    ��O      ƘK�      �  `  _  3Snow Leopard:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    S n o w   L e o p a r d  &System/Library/CoreServices/Finder.app  / ��  ��  ��       ������  � ��
�� .aevtoappnull  �   � ****� �����������
�� .aevtoappnull  �   � ****� k     ��  ����  ��  ��  �  � 7����� �������� ,�� 4������ W������������ � ��� � ��������������� ������������� ���;C��K��S��h}����
�� 
vers�� 0 
os_version  
�� afdmcusr
�� .earsffdralis        afdr
�� 
psxp�� 0 user_folder  �� 0 automator_folder  �� 0 services_folder  
�� 
utxt�� 0 
cwd_folder  �� 0 rsrc_folder  
�� 
cobj
�� 
ctnr�� 0 parent_folder  
�� 
ctxt�� 0 home_folder  �� 0 library_folder  �� 0 src_file  
�� 
cfol
�� .coredoexbool        obj 
�� 
kocl
�� 
insh
�� 
prdt
�� 
pnam�� 
�� .corecrel****      � null
�� 
file
�� 
alrp�� 
�� .coreclon****      � ****
�� .sysodlogaskr        TEXT�� 0 workflows_folder  �� 0 apps_folder  �� 0 finder_folder  ����*�,E�O����j �,E�O��%E�O��%E�O)j �&E�O��%E�O*a �/a ,�&E` O�j a &E` O�a  ~_ a %E` O_ a %E�O�a %E` O*a �/j f  #*a a a _ a a  a !la " #Y hO*a $_ /a *a �/a %ea & 'Oa (�%j )OPY_ a *%E` O_ a +%E` ,O_ a -%E` .O_ a /%E` 0O*a _ ,/j f  #*a a a _ a a  a 1la " #Y hO*a _ ./j f  #*a a a _ ,a a  a 2la " #Y hO*a _ 0/j f  #*a a a _ .a a  a 3la " #Y hO*a _ 0/j e  :�a 4%E` O*a $_ /a *a _ 0/a %ea & 'Oa 5_ 0%j )OPY hOPOPY 	a 6j )OPUascr  ��ޭ