(require :robot-interface "package://pr2eus/robot-interface.l")
(require :dual_franka "package://franka_description/dual_franka.l")

(defclass dual_franka-robot-interface
  :super robot-interface
  :slots ())
(defmethod dual_franka-robot-interface
  (:init
   (&rest args &key ((:controller-timeout ct) nil))
   (prog1
       (send-super* :init :robot dual_franka-robot :controller-timeout ct args)
     ;; do something
     ))
  #|
  (:default-controller
   ()
   (list
    (list
     (cons :controller-action "fullbody_controller/follow_joint_trajectory")
     (cons :controller-state "fullbody_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n))
                                (send-all (send robot :joint-list) :name))))))
  |#
  (:default-controller
   ()
   (list
    (car (send self :larm-controller))
    (car (send self :rarm-controller))
    (car (send self :head-controller))
    (car (send self :lhand-controller))
    (car (send self :rhand-controller))
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
  )
;; grasp controller ...
(defun dual_franka-init ()
  (setq *ri* (instance dual_franka-robot-interface :init))
  (setq *robot* (dual_franka))
  )
