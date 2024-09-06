// attendance/getWorkingHoursForWeek.js

import supabase from '../db';
import { addDays,startOfWeek,endOfWeek } from 'date-fns';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { employee_id,weekStart } = req.query;

        const start = startOfWeek(new Date(weekStart));
        const end = endOfWeek(new Date(weekStart));

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .eq('employee_id',employee_id)
            .gte('timestamp',start.toISOString())
            .lte('timestamp',end.toISOString());

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        // Calculate working hours similar to daily calculation
        let workingHours = 0;
        let lastCheckInTime = null;

        data.forEach((record) => {
            if (record.event_type === 'checkin') {
                lastCheckInTime = new Date(record.timestamp);
            } else if (record.event_type === 'checkout' && lastCheckInTime) {
                const checkOutTime = new Date(record.timestamp);
                workingHours += (checkOutTime - lastCheckInTime) / (1000 * 60 * 60);
                lastCheckInTime = null;
            }
        });

        return res.status(200).json({ workingHours });
    } else {
        res.setHeader('Allow',['GET']);
        return res.status(405).json({ message: `Method ${req.method} not allowed` });
    }
}
