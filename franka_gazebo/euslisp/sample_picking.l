;;
;; pickup cutter
;;

(ros::load-ros-manifest "roseus")
(ros::load-ros-manifest "gazebo_msgs")
(load "package://franka_description/dual_franka-interface.l")
(dual_franka-init)
(objects (list *robot*))


(defun get-grasp-coords (target-name)
  ;;
  ;; Getting coordinate of cutter using /gazebo/model_states topic.
  ;; 
  (let (msg names (cnt 0) idx target-pose target-coords target-twists)
    (setq msg (one-shot-subscribe "/gazebo/model_states" gazebo_msgs::ModelStates))
    (setq names (send msg :name) poses (send msg :pose) twists (send msg :twist))
    (dolist (n names)
      (cond ((string= n target-name)
             (setq idx cnt)
             (return))
            (t (incf cnt)
               )))
    (setq target-pose (elt poses idx))
    (setq target-coords (ros::tf-pose->coords target-pose))
    (setq target-twists (elt twists idx))
    (send target-coords :draw-on :flush t :size 200 :width 5 :color #f(1 0 0))
    target-coords))

(defun pickup-object nil
  ;;
  ;; Approach to object and pickup cutter.
  ;;
  (setq c (get-grasp-coords "jsk_cutter"))
  (setq cc (send (make-coords :pos (send c :worldpos) :rpy (float-vector 0 pi/2 0)) :translate #f(0 0 10) :world))
  (setq approach-cc (send (send cc :copy-worldcoords) :translate #f(0 0 70) :world))
  (send approach-cc :draw-on :flush t :size 100 :width 5 :color #f(1 0 0))
  (send *robot* :larm :inverse-kinematics approach-cc)
  (send *Ri* :stop-grasp :larm)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  
  (send *robot* :larm :inverse-kinematics cc)
  (send *ri* :angle-vector (send *robot* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp :larm :wait t)
  
  (send *robot* :larm :inverse-kinematics approach-cc)
  (send *ri* :angle-vector (send *robot* :angle-vector) 2000)
  (send *ri* :wait-interpolation)
  )

(pickup-object)
(eixt)
