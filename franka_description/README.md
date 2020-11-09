# compile urdf/euslisp model
```
rosrun xacro xacro --inorder robots/dual_panda_robot.urdf.xacro > dual_franka.urdf
```

```
rosrun euscollada collada2eus -I dual_franka.urdf -C dual_franka.yaml -O dual_franka.l
```