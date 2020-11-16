# compile urdf/euslisp model at franka_description

https://github.com/YoheiKakiuchi/franka_ros/tree/add_dual_arm/franka_description

```
rosrun xacro xacro --inorder robots/dual_panda_robot.urdf.xacro > dual_franka.urdf
```

```
rosrun euscollada collada2eus -I dual_franka.urdf -C dual_franka.yaml -O dual_franka.l
```


```
roslaunch franka_gazebo dual_franka_gazebo.launch
```
you should press the start button, because gazebo was launched with paused mode.