  program FEMGeo_Wr
!-----------------------------------------------------------------------------------!
!  Program pip:                                                                     !
!  Point in Polyhedron                                                              !
!  Original version 0.80125 (2008 January 25) (Subversion:9) by Roman Schuh         !
!  Further changes are tracked by version control of ADDA, see also README          !
!  (uses I0 format identifier from Fortran95 standard)                              !
!                                                                                   !
!  The program calls the ivread_wr.f90 subroutine.                                  !
!  This routine is based on the ivread.f90 routine by John Burkardt (1999).         !
!  The program converts various computer graphics files formates                    !
!  (dxf, obj, oogl, smf, vmrl) into the .FEM format needed with TNONAXSYM.          !
!  (Have a look at the comments in ivread).                                         !
!                                                                                   !
!  But the focus of the program FEMGeo_Wr is on the wavefront .obj file format.     !
!  The input .obj file should such be such that it only consists of triangular (!!) !
!  surface patches! No free form curves are supported.                              !
!  All dimensions are in microns.                                                   !
!                                                                                   !
!  This .obj file format will also be generated by the SScaTT (superellipsoid       !
!  scattering tool), which is also included on this CD.                             !
!  FEMGeo has not been tested with the other file formats that can be read by the   !
!  ivread.f90 routine.                                                              !
!                                                                                   !
!  The Hyperfun program (www.hyperfun.org) is suitable for generation of other      !
!  particle shapes. For conversion to .obj, visualization and scaling you may use   !
!  Deep Exploration (www.righthemisphere.com), for grid reduction you may use       !
!  Rational Reducer Professional (www.rational-reducer.com).                        !
!  To increase the number of faces of a body you can use a divide by four           !
!  subdivision scheme implemented in the Triangles                                  !
!  DOS program (www.geocities.com/Athens/Academy/8764/triangdoc.html).              !
!  A divide by three or by four scheme is also included in MilkShape-1.5.7.         !
!                                                                                   !
!-----------------------------------------------------------------------------------!
  integer, parameter :: face_max = 100000
  integer, parameter :: node_max = 100000
  integer, parameter :: face_order_max = 3

  integer node_num
  integer na, ppos
  integer face_num, n_surfaces
  real face_point(3,face_max)
  real face_normal(3,face_max)
  real face_area(face_max)
  character (len = 100) filein_name,name_out
  integer face_order(face_max)
  integer face(face_order_max,face_max)
  real v4(3,node_max)
  real (kind = 8) vv(3,node_max)
  real (kind = 8) pp(3)
  logical inside
  
  integer NAT,MXNAT,error
  integer, dimension(:), allocatable :: ICOMP
  integer, dimension(:,:), allocatable :: IXYZ
  real A1(3),A2(3),DX(3)
  integer JX,JY,JZ,NB,NFAC,NLAY,NX2,NY1,NY2,NZ1,NZ2
  real ASPR,PI,REFF2,Y2M,YCM,Z2,ZCM

  real xave,xrange
  real xmax
  real xmin
  real yave,yrange
  real ymax
  real ymin
  real zave,zrange
  real zmax
  real zmin
  real maxxyz,xyzscale
  real array (3)
  integer maxpos,numiargc
  integer NBX,NBY,NBZ
  integer xsh,ysh,zsh, shape_size
  character*80 strafg
  
!
!   only particles consisting of one (!) closed surface are considered 
!
    n_surfaces=1

    numiargc=iargc()

    if(numiargc == 0) then
        shape_size = 80
        filein_name='shape.obj'
    else if(numiargc == 1) then
        call getarg(1,strafg)
        read(unit=strafg,fmt=*)shape_size
        filein_name='shape.obj'
    else
        call getarg(1,strafg)
        read(unit=strafg,fmt=*)shape_size
        call getarg(2,strafg)
        read(unit=strafg,fmt=*)filein_name
    endif
!   check for presence of extension of filename, add .obj if none
    ppos=scan(filein_name,".",BACK=.true.)
	print *,'!!!',filein_name,'!!!'
    if(ppos > 0) then
        name_out = filein_name(1:ppos)//'dat'
    else
		name_out = trim(filein_name)//'.dat'
        filein_name = trim(filein_name)//'.obj'
    endif

    print *, 'Maximum shape size = ', shape_size
    print *, 'Input file = ', filein_name
    print *, 'Output file = ', name_out

    xsh = shape_size
    ysh = shape_size
    zsh = shape_size
    
    NAT = 0
    DX(1) = 1.0
    DX(2) = 1.0
    DX(3) = 1.0
    
    face_order = 3

    call ivread_wr(filein_name,face_point,face_normal,face_area,face_num,node_num,v4,face)
    
    vv(1:3,1:node_num)=dble(v4(1:3,1:node_num))
    
    call cor3_limits(node_max, node_num, v4,&
         xmin, xave, xmax, ymin, yave, ymax, zmin, zave, zmax)
    
    PI=4.*atan(1.)

    do JX=1,3
        A1(JX)=0.
        A2(JX)=0.
    enddo
    A1(1)=1.
    A2(2)=1.

    xrange=xmax-xmin
    yrange=ymax-ymin
    zrange=zmax-zmin

    maxxyz=max(xrange,yrange,zrange)
    array(1)=xrange
    array(2)=yrange
    array(3)=zrange
    maxpos=maxloc(array,1)

    if(maxpos == 1)then
        NBX=xsh
        NBY=int(yrange/xrange*xsh)
        NBZ=int(zrange/xrange*xsh)
        xyzscale=xsh/xrange
    endif
    if(maxpos == 2)then
        NBX=int(xrange/yrange*ysh)
        NBY=ysh
        NBZ=int(zrange/yrange*ysh)
        xyzscale=ysh/yrange
    endif
    if(maxpos == 3)then
        NBX=int(xrange/zrange*zsh)
        NBY=int(yrange/zrange*zsh)
        NBZ=zsh
        xyzscale=zsh/zrange
    endif


    if(2*(NBX/2).LT.NBX)then
        XCM=0.
        NX1=-NBX/2
        NX2=NBX/2
    else
        XCM=0.5
        NX1=-NBX/2+1
        NX2=NBX/2
    endif
    if(2*(NBY/2).LT.NBY)then
        YCM=0.
        NY1=-NBY/2
        NY2=NBY/2
    else
        YCM=0.5
        NY1=-NBY/2+1
        NY2=NBY/2
    endif
    if(2*(NBZ/2).LT.NBZ)then
        ZCM=0.
        NZ1=-NBZ/2
        NZ2=NBZ/2
    else
        ZCM=0.5
        NZ1=-NBZ/2+1
        NZ2=NBZ/2
    endif

    MXNAT=NBX*NBY*NBZ
    allocate(ICOMP(MXNAT),stat=error)
    if(error /= 0) then
        print*,'error: could not allocate memory for ICOMP, MXNAT=',MXNAT
        stop
    endif
    allocate(IXYZ(MXNAT,3),stat=error)
    if(error /= 0) then
        print*,'error: could not allocate memory for IXYZ(3), MXNAT=',MXNAT
        stop
    endif

    do JZ=NZ1,NZ2
        do JY=NY1,NY2
            do JX=NX1,NX2
                pp(1)=1.1*dble(JX)/dble(xyzscale)+dble(xmax+xmin)/2.
                pp(2)=1.1*dble(JY)/dble(xyzscale)+dble(ymax+ymin)/2.
                pp(3)=1.1*dble(JZ)/dble(xyzscale)+dble(zmax+zmin)/2.
                call polyhedron_contains_point_3d ( node_num, face_num, &
                     face_order_max, vv, face_order, face, pp, inside )
                if(inside .eqv. .true.) then
                    NAT=NAT+1
                    IXYZ(NAT,1)=JX
                    IXYZ(NAT,2)=JY
                    IXYZ(NAT,3)=JZ
!                   The following will be needed if extending to multi-domain particles
                    ICOMP(NAT)=1
                endif
            enddo
        enddo
        write(*,*)JZ,NAT
    enddo

    write(*,*)NAT
    open(unit=12,file=name_out,status='UNKNOWN')
    write(12,fmt=92)NBX,NBY,NBZ,NAT,A1,A2,DX
    do JX=1,NAT
        write(12,fmt=93)JX,IXYZ(JX,1),IXYZ(JX,2),IXYZ(JX,3),ICOMP(JX),ICOMP(JX),ICOMP(JX)
    enddo
    close(unit=12)
    
    deallocate(ICOMP)
    deallocate(IXYZ)

92  format(' >PIPOBJ: point-in-polyhedron: NBX, NBY, NBZ=',3(' ',I0),/,&
        ' ',I0,' = NAT',/,&
        3F7.4,' = A_1 vector',/,&
        3F7.4,' = A_2 vector',/,&
        3F7.4,' = lattice spacings (d_x,d_y,d_z)/d',/,&
        ' 0.0 0.0 0.0',/,&
        ' JA IX IY IZ ICOMP(x,y,z)')
!   sacrifices text alignment to minimize file size; still contains leading space on each line
93  format(7(' ',I0))

end

