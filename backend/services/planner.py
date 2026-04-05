import uuid
from datetime import datetime, timedelta
from typing import List, Tuple
from models import PlanRequest, PlanResponse, Block

def parse_time(time_str: str) -> int:
    """Safely parse HH:MM into raw minutes."""
    parts = time_str.split(':')
    return int(parts[0]) * 60 + int(parts[1])

def format_time(minutes: int) -> str:
    """Format raw minutes back to HH:MM."""
    # Ensure it wraps around midnight gracefully
    minutes = minutes % (24 * 60)
    hours = minutes // 60
    mins = minutes % 60
    return f"{hours:02d}:{mins:02d}"

def generate_study_plan(request: PlanRequest) -> PlanResponse:
    blocks: List[Block] = []
    warnings: List[str] = []
    
    if not request.subjects:
        warnings.append("No subjects provided. Returning empty plan.")
        return PlanResponse(plan_id=str(uuid.uuid4()), blocks=blocks, warnings=warnings)
        
    subject_index = 0
    
    for slot in request.time_slots:
        if len(slot) != 2:
            continue
            
        start_min = parse_time(slot[0])
        end_min = parse_time(slot[1])
        
        # Handle midnight crossing
        if end_min < start_min:
            end_min += 24 * 60
            
        slot_duration = end_min - start_min
        
        if slot_duration < 15:
            warnings.append(f"Ignored slot {slot[0]}-{slot[1]} (Under 15 minutes)")
            continue
            
        current_time = start_min
        
        # Quick Review Mode for short blocks
        if slot_duration < 45:
            # Generate 15-minute quick reviews
            while current_time + 15 <= end_min:
                next_time = current_time + 15
                subject = request.subjects[subject_index % len(request.subjects)]
                
                blocks.append(Block(
                    subject=subject,
                    type="review",
                    start=format_time(current_time),
                    end=format_time(next_time)
                ))
                
                current_time = next_time
                subject_index += 1
                
        # Standard Focus Mode
        else:
            # Generate 45 min study / 15 min break loops
            while current_time + 45 <= end_min:
                next_time = current_time + 45
                subject = request.subjects[subject_index % len(request.subjects)]
                
                # 45 min study block
                blocks.append(Block(
                    subject=subject,
                    type="study",
                    start=format_time(current_time),
                    end=format_time(next_time)
                ))
                
                current_time = next_time
                subject_index += 1
                
                # 15 min break block (if there is space left)
                if current_time + 15 <= end_min:
                    next_break = current_time + 15
                    blocks.append(Block(
                        subject="Break",
                        type="break",
                        start=format_time(current_time),
                        end=format_time(next_break)
                    ))
                    current_time = next_break
                    
    return PlanResponse(
        plan_id=str(uuid.uuid4()),
        blocks=blocks,
        warnings=warnings
    )
