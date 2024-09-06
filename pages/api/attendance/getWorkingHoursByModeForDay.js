// attendance/getWorkingHoursByModeForDay.js

import supabase from '../db';

export default async function handler(req,res) {
    if (req.method === 'GET') {
        const { employee_id,date,mode } = req.query;

        const { data,error } = await supabase
            .from('attendance')
            .select('*')
            .eq('employee_id',employee_id)
            .eq('mode',mode)
            .gte('timestamp',`${date} 00:00:00`)
            .lte('timestamp',`${date} 23:59:59`);

        if (error) {
            return res.status(400).json({ error: error.message });
        }

        // Calculate working hours by pairing check-in/check-out events
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
