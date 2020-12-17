(require :robot-interface "package://pr2eus/robot-interface.l")
(require :dual_franka "package://franka_description/dual_franka.l")

(defclass dual_franka-robot-interface
  :super robot-interface
  :slots (gripper-action l-gripper-action gazebop))

(defmethod dual_franka-robot-interface
  (:init
   (&rest args &key ((:controller-timeout ct) nil))
   (prog1
       (send-super* :init :robot dual_franka-robot :controller-timeout ct args)
     ;; check whather the environement is Gazebo
     (setq gazebop (numberp (ros::get-param "/gazebo/time_step")))
     (if gazebop (ros::ros-warn "Using Gazebo environment"))

     ;; Controller setting for Gazebo environment
     (when gazebop
       (ros::subscribe "/rhand_controller/state" control_msgs::JointTrajectoryControllerState
                       #'send self :gripper-state-callback :rarm :groupname groupname)
       (ros::subscribe "/lhand_controller/state" control_msgs::JointTrajectoryControllerState
                       #'send self :gripper-state-callback :larm :groupname groupname)
       (setq r-gripper-action (instance ros::simple-action-client :init
                                        "/rhand_controller/follow_joint_trajectory"
                                        control_msgs::FollowJointTrajectoryAction))
       (setq l-gripper-action (instance ros::simple-action-client :init
                                        "/lhand_controller/follow_joint_trajectory"
                                        control_msgs::FollowJointTrajectoryAction))
     (dolist (action (list r-gripper-action l-gripper-action))
       (unless (and joint-action-enable (send action :wait-for-server 3))
         (setq joint-action-enable nil)
         (ros::ros-warn "~A is not respond" action)
         (return))))
     (unless gazebop
       (ros::ros-warn "real franka environemt interface is not impelemented")) ;; TODO
   ))
  (:default-controller
   ()
   (list
    (car (send self :larm-controller))
    (car (send self :rarm-controller))
    (car (send self :head-controller))
    ))
  (:larm-controller
   ()
   (list
    (list
     (cons :controller-action "larm_controller/follow_joint_trajectory")
     (cons :controller-state "larm_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names
           (remove-if #'(lambda (jn) (substringp "finger" jn))
                      (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n))
                              (send-all (send robot :larm :joint-list) :name)))))))
  (:rarm-controller
   ()
   (list
    (list
     (cons :controller-action "rarm_controller/follow_joint_trajectory")
     (cons :controller-state "rarm_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names
           (remove-if #'(lambda (jn) (substringp "finger" jn))
                      (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n))
                              (send-all (send robot :rarm :joint-list) :name)))))))
  (:head-controller
   ()
   (list
    (list
     (cons :controller-action "head_controller/follow_joint_trajectory")
     (cons :controller-state "head_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n))
                                (send-all (send robot :head :joint-list) :name))))))
  (:lhand-controller
   ()
   (list
    (list
     (cons :controller-action "lhand_controller/follow_joint_trajectory")
     (cons :controller-state "lhand_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "left_finger_joint1" "left_finger_joint2") ))))
  (:rhand-controller
   ()
   (list
    (list
     (cons :controller-action "rhand_controller/follow_joint_trajectory")
     (cons :controller-state "rhand_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (list "right_finger_joint1" "right_finger_joint2") ))))
  (:start-grasp
   (arm &key (wait nil)) ;; TODO :arms is not implemented
   (unless (memq arm '(:larm :rarm))
     (error "you must specify arm ~A from ~A" (car args) '(:larm :rarm))
     (return-from :start-grasp nil))
   (send self :move-gripper arm -0.01 :effort 1.0 :wait wait)
   )
  (:stop-grasp
   (arm &key (wait nil)) ;; TODO :arms is not implemented
   (unless (memq arm '(:larm :rarm))
     (error "you must specify arm ~A from ~A" (car args) '(:larm :rarm))
     (return-from :stop-grasp nil))
   (send self :move-gripper arm 0.05 :effort 1.0 :wait wait)
   )
  (:get-table nil controller-table)
  (:move-gripper
   (arm pos &key (effort 25) (tm 500) (timeout 5000) (wait nil))  ;; TODO :arms is not implemented
   (let* ((start-time 0.1) ;; TODO fixed start-time
          (action (case arm
                        (:rarm r-gripper-action)
                        (:larm l-gripper-action)))
          (joint-names (case arm
                             (:rarm (cdr (assoc :joint-names (car (send self :rhand-controller)))))
                             (:larm (cdr (assoc :joint-names (car (send self :lhand-controller)))))))
          (goal (send action :make-goal-instance))
          (st (if (numberp start-time)
                  (ros::time+ (ros::time-now) (ros::time start-time))
                start-time)))
     ;; send command
     (send goal :header :seq 1)
     (send goal :header :stamp st)
     (send goal :goal :trajectory :joint_names joint-names)
     (send goal :goal :trajectory :header :stamp st)
     (send goal :goal :trajectory :points
           (list (instance trajectory_msgs::JointTrajectoryPoint
                           :init
                           :positions (float-vector pos pos)
                           :effort (float-vector effort effort)   ;; effort control
                           :time_from_start (ros::time (/ tm 1000.0)))))
     (send self :spin-once)
     (send action :send-goal goal)
     (cond (wait (send action :wait-for-result :timeout timeout))))) ;; wait if needed
  (:gripper
   (&rest args)
   (when (eq (car args) :arms)
     (return-from :gripper
                  (mapcar #'(lambda (x)
                              (send self :gripper x (cadr args)))
                          '(:larm :rarm))))
   (unless (memq (car args) '(:larm :rarm))
     (error "you must specify arm ~A from ~A" (car args) '(:larm :rarm))
     (return-from :gripper nil))
   (send self :state
         (intern
          (format nil "~A-~A" (string (car args)) (string (cadr args)))
          *keyword-package*)))
  (:gripper-state-callback
   (arm msg)
   (let* ((poss (send (send msg :actual) :positions))
          (vels (send (send msg :actual) :velocities)))
     (dolist (i (list
                 (cons (format nil "~A-POSITION" (string arm))
                       (* 1000.0 (/ (+ (elt poss 0) (elt poss 1)) 2)))
                 (cons (format nil "~A-VELOCITY" (string arm))
                       (* 1000.0 (/ (+ (elt vels 0) (elt vels 1)) 2)))))
     (send self :set-robot-state1 (intern (car i) *keyword-package*) (cdr i)))))
   )


;; grasp controller ...
(defun dual_franka-init ()
  (setq *ri* (instance dual_franka-robot-interface :init))
  (setq *robot* (dual_franka))
  )
